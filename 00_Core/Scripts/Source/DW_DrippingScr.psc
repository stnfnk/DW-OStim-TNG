Scriptname DW_DrippingScr extends ReferenceAlias

DW_CORE Property CORE Auto

Event OnInit()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  If CORE
    CORE.Startup()
  Else
    Debug.Trace("DW_DrippingScr - Unable to initialize CORE reference")
  EndIf
Endevent

;rebuild json
;function DW_JsonRebuild()
; JsonUtil.SetStringValue("/DW/Strings", "VirLost", "You have lost your virginity!")
; JsonUtil.SetStringValue("/DW/Strings", "VirGain", "You have claimed virginity!")
; JsonUtil.SetStringValue("/DW/Strings", "Vir1", "First Blood!")
; JsonUtil.SetStringValue("/DW/Strings", "Vir2", "Power Play!")
; JsonUtil.SetStringValue("/DW/Strings", "Vir3", "Brutality!")
; JsonUtil.SetStringValue("/DW/Strings", "Vir4", "Domination!")
; JsonUtil.SetStringValue("/DW/Strings", "Vir5", "Complete Annihilation!")
; JsonUtil.SetStringValue("/DW/Strings", "ScriptInitFail", "Dripping when aroused was not installed correctly, scripts are not running. \n This can be false alarm when starting new game but if message keeps repeating, then something is wrong, reinstall with correct plugins.")
;EndFunction

Event OnPlayerLoadGame()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  If CORE
    CORE.Startup()
  Else
    Debug.Trace("DW_DrippingScr - Failed to get CORE reference on player load game")
  EndIf
EndEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
  ; Get actor reference and validate
  Actor akActor = GetActorRef()
  If !akActor
    Debug.Trace("DW_DrippingScr - OnObjectUnequipped - No actor reference")
    Return
  EndIf
  
  ; Validate CORE
  If !CORE
    Debug.Trace("DW_DrippingScr - OnObjectUnequipped - Missing CORE reference")
    Return
  EndIf
  
  ; Check if we have at least one gag detection system available
  Bool hasDDi = (CORE.DDi != None)
  Bool hasZBF = (CORE.zbf != None)
  
  If !hasDDi && !hasZBF
    Debug.Trace("DW_DrippingScr - OnObjectUnequipped - No gag detection interfaces available")
    Return
  EndIf
  
  ; Check if wearing any gag using available systems
  Bool isWearingGag = False
  
  If hasDDi && CORE.DDi.IsWearingDDGag(akActor)
    isWearingGag = True
  EndIf
  
  If !isWearingGag && hasZBF && CORE.zbf.IsWearingZaZGag(akActor)
    isWearingGag = True
  EndIf
  
  ; If not wearing any gag, remove the spell
  If !isWearingGag && akActor.HasSpell(CORE.DW_DrippingGag_Spell)
    akActor.RemoveSpell(CORE.DW_DrippingGag_Spell)
  EndIf
EndEvent
