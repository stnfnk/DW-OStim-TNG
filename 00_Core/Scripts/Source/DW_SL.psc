Scriptname DW_SL extends quest

DW_CORE property CORE auto

Quest ActorsQuest

Keyword TNG_Gentlewoman
Keyword TNG_XL


Event OnInit()
  ; Pre-initialize commonly used forms
  if CORE.Plugin_Appr2
    ActorsQuest = Game.GetFormFromFile(0x02902C, "Apropos2.esp") as Quest
  EndIf
  if CORE.Plugin_TNG
    TNG_Gentlewoman = Game.GetFormFromFile(0xFF8, "TheNewGentleman.esp") as Keyword
    TNG_XL = Game.GetFormFromFile(0xFE5, "TheNewGentleman.esp") as Keyword
  EndIf
  RegisterForModEvent("ostim_thread_start", "OStimManager")
EndEvent


int Function GetGender(Actor akActor)
  if !akActor
    return -1 ; Invalid actor
  endif  
  if CORE.Plugin_TNG
    if akActor.GetActorBase().GetSex() == 1 && !akActor.HasKeyword(TNG_Gentlewoman)
      return 1 ; Female
    else
      return 0 ; Male
    endif
  elseif CORE.Plugin_SL
    Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
    if SexLabQuest
      SexLabFramework SexLab = SexLabQuest as SexLabFramework
      return SexLab.GetGender(akActor)
    endif
  endif
  return akActor.GetLeveledActorBase().GetSex()
EndFunction


string Function GetActorName(actor akActor)
  if akActor == Game.GetPlayer()
    return akActor.GetActorBase().GetName()
  else
    return akActor.GetDisplayName()
  EndIf
EndFunction


Function MinAI_RegisterEvent(string eventLine, string eventType)
 int handle = ModEvent.Create("MinAI_RegisterEvent")
  if (handle)
    ModEvent.PushString(handle, eventLine)
    ModEvent.PushString(handle, eventType)
    ModEvent.Send(handle)
  endIf
EndFunction


Function MinAI_RequestResponse(string eventLine, string eventType, string targetName)
  int handle = ModEvent.Create("MinAI_RequestResponse")
    if (handle)
      ModEvent.PushString(handle, eventLine)
      ModEvent.PushString(handle, eventType)
      ModEvent.PushString(handle, targetName)
      ModEvent.Send(handle)
    endIf
EndFunction


Event OStimManager(string eventName, string _args, float numArg, Form sender)
  if !CORE.Plugin_OStim
    return
  endif
  if eventName=="ostim_actor_orgasm"
    Orgasm(sender as Actor, _args)
    return
  endif  
  int ostimTid = numArg as int
  if eventName == "ostim_thread_start"
    Actor akActor = Game.GetPlayer()
    if OActor.IsInOstim(akActor)
      CORE.DW_bAnimating.SetValue(1)
      if CORE.DW_ModState09.GetValue() == 1
        akActor.RemoveSpell(CORE.DW_Visuals_Spell)
      endif
      if CORE.DW_ModState10.GetValue() == 1
        akActor.RemoveSpell(CORE.DW_Heart_Spell)
        akActor.RemoveSpell(CORE.DW_Breath_Spell)
      endif
    endif
  elseif eventName == "ostim_thread_scenechanged"
    ; Process virginity checks
    ProcessVirginityChecks(ostimTid)
  elseif eventName == "ostim_thread_end"
    CORE.DW_bAnimating.SetValue(0)
  endif
EndEvent


Function ProcessVirginityChecks(int ostimTid)
  if !CORE.DW_ModState13.GetValue() == 1 || !CORE.Plugin_OStim
    return
  endif
  Actor[] actors = OThread.GetActors(ostimTid)
  string ostimScene = OThread.GetScene(ostimTid)
  if !actors || actors.Length < 2
    return
  endif
  int vaginal = OMetadata.FindActionForTarget(ostimScene, 1, "vaginalsex")
  if GetGender(actors[0]) == 0 && GetGender(actors[1]) == 1 && vaginal != -1
    ProcessVirginityLoss(actors[0], actors[1])
  endif
EndFunction


Function ProcessVirginityLoss(Actor activeActor, Actor passiveActor)
  if JsonUtil.FormListHas("/DW/NonVirginNPCList", "not_a_virgin", passiveActor.GetLeveledActorBase())
    return
  endif
  if ActorsQuest && DW_Appr2.GetVaginalWearState0to10(passiveActor, ActorsQuest) > 6
    simulateDamagedVagina(passiveActor)
  endif
  if CORE.DW_VirginsList.Find(passiveActor) != -1
    return
  endif
  if CORE.DW_bSLStatsIgnore.GetValue() != 1 && passiveActor != Game.GetPlayer()
    CORE.DW_VirginsList.AddForm(passiveActor)
    return
  endif
  
  ; Player losing virginity
  if passiveActor == Game.GetPlayer() && CORE.DW_bPlayerIsVirgin.GetValue() == 1
    debug.Notification("$DW_VIRGINITYLOST")
    CORE.DW_bPlayerIsVirgin.SetValue(0)
    CORE.DW_PlayerVirginityLoss.SetValue(CORE.DW_PlayerVirginityLoss.GetValue() + 1)
    
  ; Player claims npc virginity
  elseif activeActor == Game.GetPlayer()
    debug.Notification("$DW_VIRGINSCLAIMED")
    CORE.DW_VirginsClaimed.AddForm(passiveActor)
    CORE.DW_VirginsClaimedTG.AddForm(passiveActor)
    ProcessVirginityMilestones()
  endif  
  CORE.DW_VirginsList.AddForm(passiveActor)
  CORE.DW_DrippingBlood_Spell.cast(passiveActor)  
  if CORE.Plugin_MinAI
    MinAI_RequestResponse(GetActorName(passiveActor) + " just lost her virginity to " + GetActorName(activeActor) + "!", "chatnf_sex", "everyone")
  endif
EndFunction

; Process virginity milestones
Function ProcessVirginityMilestones()
  if CORE.DW_ModState15.GetValue() != 1
    return
  endif  
  int count = CORE.DW_VirginsClaimedTG.GetSize()  
  if count == 1
    debug.Notification("$DW_FIRSTBLOOD")
  elseif count == 5
    debug.Notification("$DW_POWERPLAY")
  elseif count == 10
    debug.Notification("$DW_BRUTALITY")
  elseif count == 15
    debug.Notification("$DW_DOMINATION")
  elseif count == 25
    debug.Notification("$DW_ANNIHILATION")
  endif
EndFunction


Event OnSexLabOrgasm(String _eventName, String _args, Float _argc, Form _sender)
  if !CORE.Plugin_SL
    return
  endif
  Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
  if SexLabQuest
    SexLabFramework SexLab = SexLabQuest as SexLabFramework
    Actor[] actors = SexLab.HookActors(_args)    
    if actors && actors.Length > 0
      int idx = 0
      while idx < actors.Length
        Orgasm(actors[idx], _args)
        idx += 1
      endwhile
    endif
  endif
EndEvent


Event OnSexLabOrgasmSeparate(Form ActorRef, Int Thread)
  Actor akActor = ActorRef as Actor
  if akActor
    Orgasm(akActor, Thread as String)
  endif
EndEvent


Function Orgasm(Actor akActor, String _args)
  if !CORE.Plugin_SL && !CORE.Plugin_OStim
    return
  endif

  ; SQUIRT EFFECT - highest priority, process immediately
  bool processSquirt = CORE.DW_ModState03.GetValue() == 1 && \
                     ((CORE.DW_bUseSLGenderForSquirt.GetValue() == 1 && GetGender(akActor) == 1) || \
                      (akActor.GetLeveledActorBase().GetSex() == 1 && CORE.DW_bUseSLGenderForSquirt.GetValue() != 1))
  
  if processSquirt
    int Chance
    if CORE.DW_bSquirtChanceArousal.GetValue() != 1
      Chance = CORE.DW_SquirtChance.GetValue() as int
    else
      Chance = CORE.SLA.GetActorArousal(akActor)
    endif
    if Utility.RandomInt(0, 100) <= Chance
      ; Cast squirt spell immediately without any waits
      CORE.DW_DrippingSquirt_Spell.cast(akActor)
      if CORE.Plugin_MinAI
        MinAI_RegisterEvent(GetActorName(akActor) + " climaxed so hard she squirted!", "info_sexscene")
      endif
    endif
  endif
  
  ; MILK LEAK EFFECT - process after squirt
  bool processMilk = akActor.GetLeveledActorBase().GetSex() == 1 && \
                    ((CORE.DW_ModState16.GetValue() == 1 && akActor == Game.GetPlayer()) || \
                     (CORE.DW_ModState17.GetValue() == 1 && akActor != Game.GetPlayer()))
  if processMilk
    if CORE.Plugin_OLactis
      int level = 0
      int orgasms = 1      
      if CORE.Plugin_OStim
        orgasms = OActor.GetTimesClimaxed(akActor)
      endif
      int duration = (2 * orgasms + 3)
      if orgasms >= 5
        level = 2
      elseif orgasms >= 3
        level = 1
      endif
      int eventID = ModEvent.Create("OLactis.Lactating")
      if eventID
        ModEvent.PushForm(eventID, akActor as Form)
        ModEvent.PushInt(eventID, duration)
        ModEvent.PushInt(eventID, level)
        ModEvent.Send(eventID)
        Debug.Trace("DW sent Oninus Lactis lactation event for " + akActor.GetDisplayName())
      else
        Debug.Trace("DW failed to create Oninus Lactis ModEvent.")
      endif
    else
      CORE.DW_Milkleak_Spell.cast(akActor)
    endif    
    if CORE.Plugin_MinAI
      MinAI_RegisterEvent("Arousal and stimulation are causing milk to leak from " + GetActorName(akActor) + "'s nipples", "info_sexscene")
    endif
  endif
  
  ; CUM LEAK EFFECT - process third
  if CORE.DW_ModState02.GetValue() == 1
    ProcessCumLeakEffect(akActor, _args)
  endif
EndFunction


Function ProcessCumLeakEffect(Actor akActor, String _args)
  if CORE.Plugin_OStim
    ProcessOStimCumLeak(akActor)
  elseif CORE.Plugin_SL
    ProcessSexLabCumLeak(akActor, _args)
  endif
EndFunction


Function ProcessOStimCumLeak(Actor akActor)
  int ostimTid = OActor.GetSceneID(akActor)
  Actor[] actors = OThread.GetActors(ostimTid)
  if !actors || actors.Length < 2
    return
  endif  
  string ostimScene = OThread.GetScene(ostimTid)
  int vaginal = OMetadata.FindActionForTarget(ostimScene, 1, "vaginalsex")
  int anal = OMetadata.FindActionForTarget(ostimScene, 1, "analsex")  
  if GetGender(actors[0]) == 0 && (vaginal != -1 || anal != -1) && akActor != actors[0]
    if actors[0].GetLeveledActorBase().GetSex() != 1 || actors[0].HasKeyword(TNG_Gentlewoman)
      CORE.DW_DrippingCum_Spell.cast(actors[1])      
      if CORE.Plugin_MinAI
        MinAI_RegisterEvent(GetActorName(actors[1]) + " is leaking " + GetActorName(actors[0]) + "'s cum down their thighs", "info_sexscene")
        ProcessTNGBleedingEffect(actors[0], actors[1])
      endif
    endif
  endif
EndFunction


Function ProcessSexLabCumLeak(Actor akActor, String _args)
  Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
  if !SexLabQuest
    return
  endif  
  SexLabFramework SexLab = SexLabQuest as SexLabFramework
  Actor[] actors = SexLab.HookActors(_args)  
  if !actors || actors.Length < 2
    return
  endif  
  sslBaseAnimation animation = SexLab.HookAnimation(_args)
  if !(animation.HasTag("Anal") || animation.HasTag("Vaginal")) || akActor == actors[0]
    return
  endif  
  if CORE.SOS.GetSOS(actors[1]) == true || actors[1].GetLeveledActorBase().GetSex() != 1
    CORE.DW_DrippingCum_Spell.cast(actors[0])    
    if CORE.Plugin_MinAI
      MinAI_RegisterEvent(GetActorName(actors[0]) + " is leaking " + GetActorName(actors[1]) + "'s cum down their thighs", "info_sexscene")
      ProcessTNGBleedingEffect(actors[1], actors[0])
    endif
  endif
EndFunction


Function ProcessTNGBleedingEffect(Actor giver, Actor receiver)
  if !CORE.DW_ModState13.GetValue() == 1 || !CORE.Plugin_TNG
    return
  endif
  
  int TNG_Size = TNG_PapyrusUtil.GetActorSize(giver)
  if giver.HasKeyword(TNG_XL) || TNG_Size==4
    CORE.DW_DrippingBlood_Spell.cast(receiver)    
    if ActorsQuest && DW_Appr2.GetVaginalWearState0to10(receiver, ActorsQuest) > 6
      simulateDamagedVagina(receiver)
    endif    
    if CORE.Plugin_MinAI
      MinAI_RegisterEvent(GetActorName(receiver) + " is bleeding from being ripped open by " + GetActorName(giver) + "'s enormous cock", "info_sexscene")
    endif
  endif
EndFunction


Function simulateDamagedVagina(Actor akActor)
	if akActor != None 
		if CORE.DW_VirginsList.HasForm(akActor)
			CORE.DW_VirginsList.RemoveAddedForm(akActor)
			debug.Trace(akActor.GetLeveledActorBase().GetName() +" vagina damaged")
		endif
		if akActor == Game.GetPlayer()
			debug.Trace("PC vagina damaged")
		endif
	endif
EndFunction


Event OnSexLabStageChange(String _eventName, String _args, Float _argc, Form _sender)
	if CORE.Plugin_SL
		Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
		if (SexLabQuest)
			SexLabFramework SexLab = SexLabQuest as SexLabFramework
			;Sexlab.Log("DW OnSexLabStageChange()")			
			Actor[] actors = SexLab.HookActors(_args)
			int idx = 0
			sslBaseAnimation animation = SexLab.HookAnimation(_args)
			;SexLabUtil.PrintConsole("vaginal?" + animation.HasTag("Vaginal"))
			;SexLabUtil.PrintConsole("has sos?" + CORE.SOS.GetSOS(actors[1]))
			;SexLabUtil.PrintConsole("name + gender" + actors[0].GetLeveledActorBase().GetName() + actors[0].GetLeveledActorBase().GetSex() + " , " + actors[1].GetLeveledActorBase().GetName() + actors[1].GetLeveledActorBase().GetSex())
			if CORE.DW_ModState13.GetValue() == 1
				if animation.HasTag("Vaginal") && actors.Length > 1
					;check if dom actor(1) has penetrator and sub actor(0) has something to penetrate
					If ((CORE.SOS.GetSOS(actors[1]) == true || SexLab.Config.UseStrapons == true) || actors[1].GetLeveledActorBase().GetSex() != 1) && actors[0].GetLeveledActorBase().GetSex() == 1
						If JsonUtil.FormListHas("/DW/NonVirginNPCList", "not_a_virgin", actors[0].GetLeveledActorBase()) == true
							return
						endif
            if (ActorsQuest && DW_Appr2.GetVaginalWearState0to10(actors[0], ActorsQuest) > 6)
							simulateDamagedVagina(actors[0])
						endif
						If CORE.DW_VirginsList.Find(actors[0]) == -1
							;add non virgin npc to a list
							;check if actor sl virgin
							If SexLab.HadSex(actors[0]) && (SexLab.GetSkillLevel(actors[0], "Vaginal") > 0)
								;check if we ignore sl stats
								If CORE.DW_bSLStatsIgnore.GetValue() != 1 
									;check if actor is  not a player
									If actors[0] != Game.GetPlayer()
										CORE.DW_VirginsList.AddForm(actors[0])
										return
									endif
								endif
							endif
							
							;player loosing virginity
							If (actors[0] == Game.GetPlayer() && CORE.DW_bPlayerIsVirgin.GetValue() == 1)
								debug.Notification("$DW_VIRGINITYLOST")
								CORE.DW_bPlayerIsVirgin.SetValue(0)
								CORE.DW_PlayerVirginityLoss.SetValue(CORE.DW_PlayerVirginityLoss.GetValue() + 1)

								;player claims npc virginity
							elseif actors[1] == Game.GetPlayer() 
								debug.Notification("$DW_VIRGINSCLAIMED")
								CORE.DW_VirginsClaimed.AddForm(actors[0])
								CORE.DW_VirginsClaimedTG.AddForm(actors[0])
								If CORE.DW_ModState15.GetValue() == 1
									If CORE.DW_VirginsClaimedTG.GetSize() == 1
										debug.Notification("$DW_FIRSTBLOOD")
									elseif CORE.DW_VirginsClaimedTG.GetSize() == 5
										debug.Notification("$DW_POWERPLAY")
									elseif CORE.DW_VirginsClaimedTG.GetSize() == 10
										debug.Notification("$DW_BRUTALITY")
									elseif CORE.DW_VirginsClaimedTG.GetSize() == 15
										debug.Notification("$DW_DOMINATION")
									elseif CORE.DW_VirginsClaimedTG.GetSize() == 25
										debug.Notification("$DW_ANNIHILATION")
									endif
								endif
							endif
							CORE.DW_VirginsList.AddForm(actors[0])
							CORE.DW_DrippingBlood_Spell.cast(actors[0])
							;CORE.DW_DrippingBloodTextures_Spell.cast(actors[0])
              if CORE.Plugin_MinAI
                MinAI_RequestResponse(GetActorName(actors[0]) + " just lost her virginity to " + GetActorName(actors[1]) + "!", "chatnf_sex", "everyone")
              endif
							return
						endif
					endif
				endif
			endif
		endif
	endif
EndEvent


Event OnAnimationStart(string eventName, string strArg, float numArg, Form sender)
	if CORE.Plugin_SL
		Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
		if (SexLabQuest)
			SexLabFramework SexLab = SexLabQuest as SexLabFramework			
			sslThreadController thread = SexLab.GetController(strArg as int)
			if thread.HasPlayer == true
				Actor akActor = Game.GetPlayer()
				CORE.DW_bAnimating.SetValue(1)
				if CORE.DW_ModState09.GetValue() == 1	;remove visuals
					akActor.RemoveSpell(CORE.DW_Visuals_Spell)
				endif
				if CORE.DW_ModState10.GetValue() == 1	;remove sound
					akActor.RemoveSpell(CORE.DW_Heart_Spell)
					akActor.RemoveSpell(CORE.DW_Breath_Spell)
				endif
			endif
		endif
	endif
EndEvent


Event OnAnimationEnd(string eventName, string strArg, float numArg, Form sender)
	if CORE.Plugin_SL
		Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
		if (SexLabQuest)
			SexLabFramework SexLab = SexLabQuest as SexLabFramework			
			sslThreadController thread = SexLab.GetController(strArg as int)
			if thread.HasPlayer == true
				CORE.DW_bAnimating.SetValue(0)
			endif
		endif
	endif
EndEvent