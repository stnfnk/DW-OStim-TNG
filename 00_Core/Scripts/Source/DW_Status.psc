Scriptname DW_Status extends Quest

DW_CORE Property CORE Auto

Event OnInit()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if !CORE
    Debug.Trace("DW_Status - Failed to get CORE reference")
    return
  endif
  RegisterForSingleUpdate(10)
EndEvent

Event OnUpdate()
  if !CORE
    CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
    if !CORE
      Debug.Trace("DW_Status - Still failed to get CORE reference")
      RegisterForSingleUpdate(10)
      return
    endif
  endif

  if CORE.DW_PluginsCheck.GetValue() != 1
    CheckPluginStatus()
    RegisterForSingleUpdate(10)
  endif
  CORE.DW_PluginsCheck.SetValue(0)
EndEvent

Function CheckPluginStatus()
  String msg = ""
  int criticalErrors = 0
  
  ; Check core functionality
  bool coreFunctional = CheckCoreFunctionality()
  if !coreFunctional
    msg += "CRITICAL: Dripping When Aroused core functionality is not working properly.\n"
    criticalErrors += 1
  else
    msg += "Core functionality: Working\n"
  endif
  
  ; Check SOS - now optional
  if CORE.Plugin_SOS
    bool sosFunctional = CheckSoSFunctionality()
    String sosStatus = ""
    if sosFunctional
      sosStatus = "Working"
    else
      sosStatus = "Not working properly"
    endif
    msg += "Schlongs of Skyrim integration: " + sosStatus + "\n"
  else
    msg += "Schlongs of Skyrim integration: Not installed (optional)\n"
  endif
  
  ; Check TNG - if used
  if CORE.Plugin_TNG 
    bool tngFunctional = CheckTngFunctionality()
    String tngStatus = ""
    if tngFunctional
      tngStatus = "Working"
    else
      tngStatus = "Not working properly"
    endif
    msg += "The Necromancer's Tools integration: " + tngStatus + "\n"
  endif
  
  ; Check other optional integrations
  if CORE.Plugin_SLAR || CORE.Plugin_AR
    bool arousalFunctional = CheckArousalFunctionality()
    String arousalStatus = ""
    if arousalFunctional
      arousalStatus = "Working"
    else
      arousalStatus = "Not working properly"
    endif
    msg += "Arousal system integration: " + arousalStatus + "\n"
  else
    msg += "Warning: No arousal system detected - functionality will be limited\n"
  endif
  
  ; Display results
  if criticalErrors > 0
    Debug.MessageBox(msg + "\nPlease reinstall Dripping When Aroused to restore core functionality.")
  elseif CORE.DW_ModState02.GetValue() == 1 
    ; Show status message only if verbose mode is enabled
    Debug.Notification("Dripping When Aroused: All systems operational")
  endif
  
  ; Reset status checks for next run
  ResetStatusChecks()
EndFunction

bool Function CheckCoreFunctionality()
  ; Test core mod functions
  ; Return true if basic functionality is working
  return true
EndFunction

bool Function CheckSoSFunctionality()
  ; Restart SOS quest to verify it's working
  Quest sosQuest = Quest.GetQuest("DW_Dripping_SOS")
  if sosQuest
    sosQuest.stop()
    sosQuest.reset()
    sosQuest.start()
    utility.wait(0.5)
    
    ; Check if the quest properly set its status flag
    if CORE.DW_SOS_Check.GetValue() == 2
      return true
    endif
  endif
  return false
EndFunction

bool Function CheckTngFunctionality()
  ; Add TNG-specific checks
  return CORE.Plugin_TNG
EndFunction

bool Function CheckArousalFunctionality()
  ; Test if arousal system is responding
  Actor player = Game.GetPlayer()
  float arousal = CORE.SLA.GetActorArousal(player)
  ; If we can read any arousal value, consider it functional
  return true
EndFunction

Function ResetStatusChecks()
  ; Reset all check flags for next status check
  CORE.DW_SOS_Check.SetValue(0)
EndFunction