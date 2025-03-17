Scriptname DW_SOS extends Quest

DW_SL Property SL Auto

Event OnInit()
  ; Get CORE once and validate it
  DW_CORE CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if CORE
    CORE.DW_SOS_Check.SetValue(2)
  else
    Debug.Trace("DW_SOS - Failed to get CORE reference in OnInit")
  endif
EndEvent

bool Function GetSOS(Actor akActor)
  ; Early validation
  if !akActor
    Debug.Trace("DW_SOS - GetSOS called with None actor")
    return false
  endif
  
  bool hasSchlong = false
  DW_CORE CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if !CORE
    Debug.Trace("DW_SOS - GetSOS - Failed to get CORE reference")
    return false
  endif
  
  ; Check through TNG if available
  if CORE.Plugin_TNG
    ; Make sure SL is available
    if SL
      if SL.GetGender(akActor) == 0
        hasSchlong = True
      endif
    else
      Debug.Trace("DW_SOS - GetSOS - SL property is None")
    endif
    return hasSchlong
  endif
  
  ; Fall back to SOS if TNG is not available
  if CORE.Plugin_SOS
    Quest sosScriptQuest = Quest.GetQuest("SOS_SetupQuest")
    if sosScriptQuest
      SOS_SetupQuest_Script sosScript = sosScriptQuest as SOS_SetupQuest_Script
      if sosScript
        Faction SOS_SchlongifiedFaction = sosScript.SOS_SchlongifiedFaction
        if SOS_SchlongifiedFaction
          ; Check if actor has a schlong
          if akActor.IsInFaction(SOS_SchlongifiedFaction)
            Quest addon = sosScript.GetActiveAddon(akActor)
            if addon
              Faction addonFaction = SOS_Data.GetFaction(addon)
              if addonFaction
                ; Check if the addon is in the "NotAPenis" list
                if JsonUtil.StringListFind("/DW/SOS_NotAPenis", "notapenis", addonFaction.getname()) == -1
                  return hasSchlong
                else
                  return akActor.IsInFaction(SOS_SchlongifiedFaction)
                endif
              endif
            endif
            ; Default if we can't get addon info but actor is in faction
            return true
          endif
        else
          Debug.Trace("DW_SOS - GetSOS - SOS_SchlongifiedFaction is None")
        endif
      else
        Debug.Trace("DW_SOS - GetSOS - Failed to cast SOS_SetupQuest to SOS_SetupQuest_Script")
      endif
    else
      Debug.Trace("DW_SOS - GetSOS - SOS_SetupQuest not found")
    endif
  endif
  
  ; Default return if no schlong detected through any method
  return hasSchlong
EndFunction
