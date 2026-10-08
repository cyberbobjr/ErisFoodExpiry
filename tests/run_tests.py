"""Checks before publishing: Lua behaviour (lupa) and project validity."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "Contents/mods/batman_ErisFoodExpiry/42.21/media/lua"
LUA = MOD / "client/ErisFoodExpiry"
sys.path.insert(0, str(ROOT.parent / ".claude" / "tools"))

# Minimal doubles of the Java API used by the mod (42.21 names and semantics).
STUBS = r"""
SANDBOX = { FoodRotSpeed = 3, FridgeFactor = 3, ElecShutModifier = 14, DaysForRottenFoodRemoval = -1 }
WORLD_HOURS = 24
function getSandboxOptions()
    return {
        getOptionByName = function(_, name)
            local v = SANDBOX[name]
            if v == nil then return nil end
            return { getValue = function() return v end }
        end,
        getElecShutModifier = function() return SANDBOX.ElecShutModifier end,
    }
end
function getGameTime() return { getWorldAgeHours = function() return WORLD_HOURS end } end
function getText(key) return key end
function instanceof(o, class) return type(o) == "table" and o._class == class end
CharacterTrait = { NUTRITIONIST = "nut", NUTRITIONIST2 = "nut2", ILLITERATE = "illit" }

-- powered: ItemContainer.isPowered (generator or grid); temperature as in
-- ItemContainer.getTemperature: 0.2 for a powered fridge/freezer, else 1.0
-- unless given (stove, barbecue...).
function makeContainer(kind, generator, powered, temperature, parent)
    return {
        isFridge = function() return kind == "fridge" end,
        isFreezer = function() return kind == "freezer" end,
        isPowered = function() return powered == true end,
        getTemperature = function()
            if powered and (kind == "fridge" or kind == "freezer") then return 0.2 end
            return temperature or 1.0
        end,
        getParent = function() return parent end,
        getSourceGrid = function() return { haveElectricity = function() return generator end } end,
    }
end
function makeFood(t)
    local f = { _class = "Food" }
    function f:getAge() return t.age end
    function f:getOffAge() return t.offAge end
    function f:getOffAgeMax() return t.offAgeMax end
    function f:isFrozen() return t.frozen == true end
    function f:getFreezingTime() return t.freezingTime or (t.frozen and 100 or 0) end
    -- Food.isThawing (42.21)
    function f:isThawing()
        if self:getFreezingTime() <= 0 then return false end
        local c = t.container
        if not (c and c:isFreezer()) then return true end
        return not c:isPowered()
    end
    function f:isPackaged() return t.packaged == true end
    function f:getOutermostContainer() return t.container end
    function f:getModData() return t.modData or {} end
    return f
end
function makeChar(traits, dark)
    local c = { _class = "IsoPlayer" }
    function c:hasTrait(tr) return traits[tr] == true end
    function c:tooDarkToRead() return dark == true end
    return c
end
PZAPI = { ModOptions = { create = function(_, id, name)
    local o = { dict = {} }
    o.name = name
    function o:addTickBox(oid, name, value, tooltip)
        self.dict[oid] = { getValue = function(s) return s.value end, value = value, name = name, tooltip = tooltip }
    end
    function o:getOption(oid) return self.dict[oid] end
    return o
end } }
PROVIDERS = {}
TooltipLib = { registerProvider = function(p) PROVIDERS[#PROVIDERS + 1] = p; return true end }
package.preload["TooltipLib/Core"] = function() end
package.preload["ISUI/ISInventoryPane"] = function() end
DRAWN = {}
ISInventoryPane = { drawItemDetails = function(self) DRAWN[#DRAWN + 1] = "vanilla" end }
function getSpecificPlayer() return nil end
"""


def approx(a, b, eps=1e-6):
    return a is not None and abs(a - b) < eps


def lua_checks() -> list[str]:
    try:
        from lupa import LuaRuntime
    except ImportError:
        print("lupa not found: Lua checks skipped")
        return []
    failed: list[str] = []
    lua = LuaRuntime()
    lua.execute(STUBS)
    for name in ("EFE_Core", "EFE_Options", "EFE_Tooltip", "EFE_InventoryBar"):
        lua.execute(f'package.preload["ErisFoodExpiry/{name}"] = function() end')
    for name in ("EFE_Core", "EFE_Options", "EFE_Tooltip", "EFE_InventoryBar"):
        # getText marks translated text while loading: the provider description
        # must stay a key (MainOptions translates mod option names itself).
        lua.execute('getTextKey = getText; getText = function(k) return "T:" .. k end')
        lua.execute((LUA / f"{name}.lua").read_text(encoding="utf-8"))
        lua.execute("getText = getTextKey")
    ev = lua.eval

    def days(food: str, target: str):
        return ev(f"ErisFoodExpiry.daysUntil({food}, {target})")

    lua.execute("plain = makeFood{age=1, offAge=3, offAgeMax=5}")
    if not approx(days("plain", "3"), 2):
        failed.append("normal speed: stale in 2 days expected")
    lua.execute("SANDBOX.FoodRotSpeed = 1")  # very fast: 1.7
    if not approx(days("plain", "3"), 2 / 1.7):
        failed.append("FoodRotSpeed not applied")
    lua.execute("SANDBOX.FoodRotSpeed = 3")

    lua.execute("gen = makeFood{age=1, offAge=3, offAgeMax=5, container=makeContainer('fridge', true)}")
    if not approx(days("gen", "3"), 2 / 0.2):
        failed.append("generator fridge: fridge factor expected")
    lua.execute("SANDBOX.FridgeFactor = 6")
    if days("gen", "3") is not None:
        failed.append("fridge factor 'never': nil expected")
    lua.execute("SANDBOX.FridgeFactor = 3")

    # grid power until day 14, now day 1: 13 days at 0.2 = 2.6 age, then normal
    lua.execute("grid = makeFood{age=0, offAge=2, offAgeMax=5, container=makeContainer('freezer', false)}")
    if not approx(days("grid", "2"), 2 / 0.2):
        failed.append("grid fridge before shutoff: fridge factor expected")
    if not approx(days("grid", "5"), 13 + (5 - 2.6)):
        failed.append("grid fridge across shutoff: piecewise projection expected")
    lua.execute("SANDBOX.ElecShutModifier = -1")
    if not approx(days("grid", "2"), 2):
        failed.append("no power: normal speed expected")
    lua.execute("SANDBOX.ElecShutModifier = 14")

    lua.execute("frozen = makeFood{age=1, offAge=3, offAgeMax=5, frozen=true, "
                "container=makeContainer('freezer', false, true)}")
    if days("frozen", "3") is not None or ev("ErisFoodExpiry.thawDays(frozen)") is not None:
        failed.append("frozen food in a powered freezer must not spoil nor thaw")
    # thawing: 1.5 h from fully frozen, x2 in a powered fridge, /6 when warm
    lua.execute("thawing = makeFood{age=1, offAge=3, offAgeMax=5, frozen=true, freezingTime=50}")
    if not approx(ev("ErisFoodExpiry.thawDays(thawing)"), 0.75 / 24):
        failed.append("thaw time on the floor: 45 min expected")
    if not approx(days("thawing", "3"), 0.75 / 24 + 2):
        failed.append("spoilage starts after thawing")
    lua.execute("fridgeThaw = makeFood{age=1, offAge=3, offAgeMax=5, frozen=true, "
                "container=makeContainer('fridge', true, true)}")
    if not approx(ev("ErisFoodExpiry.thawDays(fridgeThaw)"), 3 / 24):
        failed.append("thaw time in a powered fridge: 3 h expected")
    lua.execute("stoveThaw = makeFood{age=1, offAge=3, offAgeMax=5, frozen=true, "
                "container=makeContainer('stove', false, true, 2.0)}")
    if not approx(ev("ErisFoodExpiry.thawDays(stoveThaw)"), 0.25 / 24):
        failed.append("thaw time in a warm container: 15 min expected")

    # rotten food removal: age > offAgeMax + option, composters keep it
    lua.execute("rotten = makeFood{age=6, offAge=3, offAgeMax=5}")
    if ev("ErisFoodExpiry.removalDays(rotten)") is not None:
        failed.append("removal shown while the option is off")
    lua.execute("SANDBOX.DaysForRottenFoodRemoval = 3")
    if not approx(ev("ErisFoodExpiry.removalDays(rotten)"), 2):
        failed.append("removal in 2 days expected")
    lua.execute("compost = makeFood{age=6, offAge=3, offAgeMax=5, "
                "container=makeContainer('compost', false, false, nil, { _class = 'IsoCompost' })}")
    if ev("ErisFoodExpiry.removalDays(compost)") is not None:
        failed.append("composter keeps rotten food")
    lua.execute("SANDBOX.DaysForRottenFoodRemoval = -1")
    if days("plain", "0.5") != 0:
        failed.append("past threshold: 0 expected")

    fmt = ev("ErisFoodExpiry.formatDays(365 + 30 + 14 + 1 + 2/24)")
    if fmt != "1 UI_EFE_Years 1 UI_EFE_Months 2 UI_EFE_Weeks":
        failed.append(f"formatDays order/limit: {fmt}")
    fmt = ev("ErisFoodExpiry.formatDays(1 + 5/1440)")
    if fmt != "1 UI_EFE_Days 5 UI_EFE_Minutes":
        failed.append(f"formatDays zero skipping: {fmt}")
    if ev("ErisFoodExpiry.formatDays(0)") != "< 1 UI_EFE_Minutes":
        failed.append("formatDays(0)")

    states = {
        "makeFood{age=0, offAge=3, offAgeMax=6}": "UI_EFE_StateVeryFresh",
        "makeFood{age=1.5, offAge=3, offAgeMax=6}": "UI_EFE_StateFresh",
        "makeFood{age=2.5, offAge=3, offAgeMax=6}": "UI_EFE_StateOk",
        "makeFood{age=3.5, offAge=3, offAgeMax=6}": "UI_EFE_StateRotting",
        "makeFood{age=5, offAge=3, offAgeMax=6}": "UI_EFE_StateAlmostRotten",
        "makeFood{age=6, offAge=3, offAgeMax=6}": "UI_EFE_StateRotten",
    }
    for food, key in states.items():
        if ev(f"ErisFoodExpiry.stateKey({food})") != key:
            failed.append(f"stateKey {food} -> {key}")

    read = "ErisFoodExpiry.canReadExact"
    if not ev(f"{read}(plain, nil, false)"):
        failed.append("option off: exact times for everyone")
    if ev(f"{read}(plain, makeChar{{}}, true)"):
        failed.append("option on, no trait, unpackaged: rough state expected")
    if not ev(f"{read}(plain, makeChar{{nut2=true}}, true)"):
        failed.append("Nutritionist (profession) trait not accepted")
    lua.execute("pack = makeFood{age=1, offAge=3, offAgeMax=5, packaged=true}")
    if not ev(f"{read}(pack, makeChar{{}}, true)"):
        failed.append("readable package: exact times expected")
    if ev(f"{read}(pack, makeChar{{illit=true}}, true)") or ev(f"{read}(pack, makeChar({{}}, true), true)"):
        failed.append("illiterate or too dark: package not readable")

    for food, stage in (("plain", "fresh"), ("makeFood{age=4, offAge=3, offAgeMax=5}", "stale"),
                        ("makeFood{age=5, offAge=3, offAgeMax=5}", "rotten")):
        if ev(f"ErisFoodExpiry.stage({food})") != stage:
            failed.append(f"stage {food} -> {stage}")

    # Tooltip provider
    if ev("#PROVIDERS") != 1:
        failed.append("provider not registered")
    elif ev("PROVIDERS[1].description") != "UI_EFE_TooltipProvider" or ev("ErisFoodExpiry.options.name") != "UI_EFE_Title"             or ev('ErisFoodExpiry.options:getOption("RequireTrait").name') != "UI_EFE_RequireTrait"             or ev('ErisFoodExpiry.options:getOption("RequireTrait").tooltip') != "UI_EFE_RequireTrait_tooltip":
        failed.append("option names, tooltips and provider description must be translation keys (MainOptions translates them)")
    else:
        lua.execute(r"""
        function runTooltip(item)
            local lines = {}
            local ctx = { item = item, tooltip = { getCharacter = function() return makeChar({}) end } }
            function ctx:addLabel(t) lines[#lines + 1] = "L:" .. t end
            function ctx:addKeyValue(k, v) lines[#lines + 1] = "KV:" .. k .. "=" .. v end
            function ctx:addProgress(l, f) lines[#lines + 1] = "P:" .. l .. "=" .. string.format("%.2f", f) end
            PROVIDERS[1].callback(ctx)
            return table.concat(lines, "|")
        end""")
        out = ev("runTooltip(plain)")
        if out != "P:UI_EFE_Freshness=0.80|KV:UI_EFE_StaleIn=2 UI_EFE_Days|KV:UI_EFE_RottenIn=4 UI_EFE_Days":
            failed.append(f"tooltip lines: {out}")
        out = ev("runTooltip(makeFood{age=0, offAge=1000000000, offAgeMax=1000000000})")
        if out != "L:UI_EFE_NeverPerish":
            failed.append(f"never perish: {out}")
        lua.execute('ErisFoodExpiry.options:getOption("RequireTrait").value = true')
        out = ev("runTooltip(plain)")
        if out != "P:UI_EFE_Freshness=0.80|L:UI_EFE_StateFresh":
            failed.append(f"rough state: {out}")
        out = ev("runTooltip(makeFood{age=2, offAge=3, offAgeMax=5, frozen=true, packaged=true, "
                 "container=makeContainer('freezer', false, true)})")
        if out != "P:UI_EFE_Freshness=0.60|L:UI_EFE_Frozen":
            failed.append(f"frozen tooltip: {out}")
        out = ev("runTooltip(makeFood{age=2, offAge=3, offAgeMax=5, frozen=true, packaged=true})")
        if out != ("P:UI_EFE_Freshness=0.60|KV:UI_EFE_ThawedIn=1 UI_EFE_Hours 30 UI_EFE_Minutes"
                   "|KV:UI_EFE_StaleIn=1 UI_EFE_Days 1 UI_EFE_Hours 30 UI_EFE_Minutes"
                   "|KV:UI_EFE_RottenIn=3 UI_EFE_Days 1 UI_EFE_Hours 30 UI_EFE_Minutes"):
            failed.append(f"thawing tooltip: {out}")
        lua.execute("SANDBOX.DaysForRottenFoodRemoval = 3")
        out = ev("runTooltip(makeFood{age=6, offAge=3, offAgeMax=5})")
        if out != "P:UI_EFE_Freshness=0.00|L:UI_EFE_StateRotten|KV:UI_EFE_RemovedIn=2 UI_EFE_Days":
            failed.append(f"rotten tooltip (rough state): {out}")
        lua.execute('ErisFoodExpiry.options:getOption("RequireTrait").value = false')
        out = ev("runTooltip(makeFood{age=6, offAge=3, offAgeMax=5})")
        if out != "P:UI_EFE_Freshness=0.00|L:UI_EFE_StateRotten|KV:UI_EFE_RemovedIn=2 UI_EFE_Days":
            failed.append(f"rotten tooltip: {out}")
        lua.execute("SANDBOX.FridgeFactor = 6")
        out = ev("runTooltip(makeFood{age=1, offAge=3, offAgeMax=5, container=makeContainer('fridge', true, true)})")
        if out != "P:UI_EFE_Freshness=0.80|L:UI_EFE_Paused":
            failed.append(f"no-decay fridge tooltip: {out}")
        lua.execute("SANDBOX.FridgeFactor = 3; SANDBOX.DaysForRottenFoodRemoval = -1")

    # Inventory strip keeps the vanilla line and draws two rectangles
    lua.execute(r"""
        RECTS = 0
        pane = { headerHgt = 16, itemHgt = 18, getProgressBarWidth = function() return 200 end,
                 drawRect = function() RECTS = RECTS + 1 end }
        ISInventoryPane.drawItemDetails(pane, plain, 0, 0, 0, false)
        ISInventoryPane.drawItemDetails(pane, { _class = "Clothing" }, 0, 0, 0, false)""")
    if ev("#DRAWN") != 2 or ev("RECTS") != 2:
        failed.append("inventory strip: vanilla line kept, strip on food only")
    print("Lua checks done")
    return failed


def translation_checks() -> list[str]:
    failed = []
    lua_keys = set()
    for path in LUA.glob("*.lua"):
        lua_keys |= set(re.findall(r'"(UI_EFE_\w+)"', path.read_text(encoding="utf-8")))
    for path in (MOD / "shared/Translate").glob("*/*.json"):
        keys = set(json.loads(path.read_text(encoding="utf-8")))
        missing = lua_keys - keys
        if missing:
            failed.append(f"{path.parent.name}/{path.name}: missing {sorted(missing)}")
    return failed


STEAM_TAGS = ("h1", "h2", "h3", "b", "i", "u", "list", "url", "img")
STEAM_URL = re.compile(r"\[url=([^\]]+)\]|\[img\]([^\[]+)\[/img\]")
# "\n\nWorkshop ID: <id>\nMod ID: batman_ErisFoodExpiry" added to every language on upload
UPLOAD_SUFFIX_BYTES = 70


def description_checks() -> list[str]:
    failed = []
    reference = (ROOT / "README.steam").read_text(encoding="utf-8")
    urls = Counter(STEAM_URL.findall(reference))
    for url, img in urls:
        if img and img.startswith("https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/"):
            if not (ROOT / img.split("/main/", 1)[1]).is_file():
                failed.append(f"README.steam: image missing in repo: {img}")
    for path in sorted(ROOT.glob("README.steam*")):
        text = path.read_text(encoding="utf-8")
        size = len(text.encode("utf-8"))
        if size > 8000 - UPLOAD_SUFFIX_BYTES:
            failed.append(f"{path.name}: {size} bytes")
        for tag in STEAM_TAGS:
            opened = len(re.findall(r"\[" + tag + r"(?:=[^\]]*)?\]", text))
            if opened != text.count(f"[/{tag}]"):
                failed.append(f"{path.name}: unbalanced [{tag}]")
        if Counter(STEAM_URL.findall(text)) != urls:
            failed.append(f"{path.name}: links or images differ from README.steam")
    return failed


def main() -> int:
    failed = lua_checks() + translation_checks() + description_checks()
    try:
        import pz_workshop_project as pwp
    except ImportError:
        print("pz_workshop_project not found: project validation skipped")
    else:
        failed += pwp.validate(pwp.Project.load(ROOT))
    for message in failed:
        print("FAIL", message)
    print("OK" if not failed else f"{len(failed)} failure(s)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
