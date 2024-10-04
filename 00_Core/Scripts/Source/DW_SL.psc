Scriptname DW_SL extends quest

DW_CORE property CORE auto

Keyword TNG_Gentlewoman



int Function GetGender(Actor akActor)
  if CORE.Plugin_TNG
    TNG_Gentlewoman = Game.GetFormFromFile(0x03BFF8, "TheNewGentleman.esp") as Keyword
    if !akActor.GetActorBase().GetSex() == 0 && !akActor.HasKeyword(TNG_Gentlewoman)
      return 1
    else
      return 0
    endif
	elseif CORE.Plugin_SL
		Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
		if (SexLabQuest)
			SexLabFramework SexLab = SexLabQuest as SexLabFramework
			Return SexLab.GetGender( akActor )
    endif
  else
		Return akActor.GetLeveledActorBase().GetSex()
	endif
EndFunction



Event OStimManager(string eventName, string _args, float numArg, Form sender)
  if CORE.Plugin_OStim
    int ostimTid = numArg as int

    if (eventName=="ostim_thread_start")
      Actor akActor = Game.GetPlayer()
      if OActor.IsInOstim(akActor)
        CORE.DW_bAnimating.SetValue(1)
        if CORE.DW_ModState09.GetValue() == 1	;remove visuals
          akActor.RemoveSpell(CORE.DW_Visuals_Spell)
        endif
        if CORE.DW_ModState10.GetValue() == 1	;remove sound
          akActor.RemoveSpell(CORE.DW_Heart_Spell)
          akActor.RemoveSpell(CORE.DW_Breath_Spell)
        endif
      endif
    
    elseif (eventName=="ostim_thread_scenechanged")
      ;;;viriginity stuff
      Actor[] actors = new actor[5]
      if CORE.Plugin_OStim
        actors = OThread.GetActors(ostimTid)
        string ostimScene = OThread.GetScene(ostimTid)
        if CORE.DW_ModState13.GetValue() == 1
          int vaginal = OMetadata.FindActionForTarget(ostimScene, 1, "vaginalsex")
          Utility.Wait(0.2)
          if GetGender(actors[0]) != 1 && actors[1].GetLeveledActorBase().GetSex() == 1 && vaginal != -1
            if JsonUtil.FormListHas("/DW/NonVirginNPCList", "not_a_virgin", actors[1].GetLeveledActorBase()) == true
              return
            endif
            if CORE.DW_VirginsList.Find(actors[1]) == -1
              if CORE.DW_bSLStatsIgnore.GetValue() != 1 
                ;check if actor is not a player
                if actors[1] != Game.GetPlayer()
                  CORE.DW_VirginsList.AddForm(actors[1])
                  return
                endif
              endif
              
              ;player losing virginity
              if (actors[1] == Game.GetPlayer() && CORE.DW_bPlayerIsVirgin.GetValue() == 1)
                debug.Notification("$DW_VIRGINITYLOST")
                CORE.DW_bPlayerIsVirgin.SetValue(0)
                CORE.DW_PlayerVirginityLoss.SetValue(CORE.DW_PlayerVirginityLoss.GetValue() + 1)

              ;player claims npc virginity
              elseif actors[0] == Game.GetPlayer() 
                debug.Notification("$DW_VIRGINSCLAIMED")
                CORE.DW_VirginsClaimed.AddForm(actors[1])
                CORE.DW_VirginsClaimedTG.AddForm(actors[1])
                if CORE.DW_ModState15.GetValue() == 1
                  if CORE.DW_VirginsClaimedTG.GetSize() == 1
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
              CORE.DW_VirginsList.AddForm(actors[1])
              CORE.DW_DrippingBlood_Spell.cast(actors[1])
              ;CORE.DW_DrippingBloodTextures_Spell.cast(actors[0])
              return
            endif
          endif
        endif
      endif

    elseif (eventName=="ostim_actor_orgasm")    
      Actor orgasmer = sender as Actor
      Orgasm(orgasmer, _args)

    elseif (eventName=="ostim_thread_end")    
      CORE.DW_bAnimating.SetValue(0)
    endif
  endif
EndEvent


;---------------------
;if no sexlab
;events can be removed
;---------------------

;Catch sexlab orgasm
Event OnSexLabOrgasm(String _eventName, String _args, Float _argc, Form _sender)
	if CORE.Plugin_SL
		Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
		if (SexLabQuest)
			SexLabFramework SexLab = SexLabQuest as SexLabFramework
			Actor[] actors = SexLab.HookActors(_args)
			int idx

			While idx < actors.Length
				Orgasm(actors[idx], _args)
				idx += 1
			EndWhile
		endif
	endif
EndEvent

;Catch sexlab SLSO orgasm
Event OnSexLabOrgasmSeparate(Form ActorRef, Int Thread)
	actor akActor = ActorRef as actor
	string _args =  Thread as string
	
	Orgasm(akActor, _args)
EndEvent

;process orgasm
Function Orgasm(Actor akActor, String _args)
  if !CORE.Plugin_SL && !CORE.Plugin_OStim
    return
  endif

  ;Squirt for females
  if CORE.DW_ModState03.GetValue() == 1
    if (CORE.DW_bUseSLGenderForSquirt.GetValue() == 1\
    && (GetGender(akActor) == 1) || (akActor.GetLeveledActorBase().GetSex() == 1 && CORE.DW_bUseSLGenderForSquirt.GetValue() != 1))
      int idx = 0
      int Chance = 50
      if CORE.DW_bSquirtChanceArousal.GetValue() != 1
        Chance = CORE.DW_SquirtChance.GetValue() as int
      else
        Chance = CORE.SLA.GetActorArousal(akActor)
      endif
      if Utility.RandomInt(0, 100) <= Chance
        CORE.DW_DrippingSquirt_Spell.cast( akActor )
      endif
    endif
  endif
  
  ;Milkleak for females
  if akActor.GetLeveledActorBase().GetSex() == 1
    if (CORE.DW_ModState16.GetValue() == 1 && akActor == Game.Getplayer())\
    || (CORE.DW_ModState17.GetValue() == 1 && akActor != Game.Getplayer())
      CORE.DW_Milkleak_Spell.cast( akActor )
    endif
  endif
  
  ;cum leak for reciever[0] if male/partner has penis
  ;there's fault in logic with group sex, but w/e
  if CORE.DW_ModState02.GetValue() == 1

    if CORE.Plugin_OStim
      int ostimTid = OActor.GetSceneID(akActor)
      Actor[] actors = OThread.GetActors(ostimTid)
      string ostimScene = OThread.GetScene(ostimTid)
      int vaginal = OMetadata.FindActionForTarget(ostimScene, 1, "vaginalsex")
      int anal = OMetadata.FindActionForTarget(ostimScene, 1, "analsex")
      Utility.Wait(0.2)
      if GetGender(actors[0]) == 0 && (vaginal != -1 || anal != -1) 
        if actors.Length > 1
          if akActor != actors[0]
            if actors[0].GetLeveledActorBase().GetSex() != 1 || actors[0].HasKeyword(TNG_Gentlewoman)
              Utility.Wait(1.0)
              CORE.DW_DrippingCum_Spell.cast(actors[1])
            endif
          endif
        endif
      endif

      elseif CORE.Plugin_SL
        Quest SexLabQuest = Quest.GetQuest("SexLabQuestFramework")
        if (SexLabQuest)
          Actor[] actors = new actor[5]
          SexLabFramework SexLab = SexLabQuest as SexLabFramework
          ;Sexlab.Log("DW SL Orgasm()")
          actors = SexLab.HookActors(_args)
          sslBaseAnimation animation = SexLab.HookAnimation(_args)
          if (animation.HasTag("Anal") || animation.HasTag("Vaginal")) && actors.Length > 1
            if akActor != actors[0]
              If CORE.SOS.GetSOS(actors[1]) == true || actors[1].GetLeveledActorBase().GetSex() != 1
                Utility.Wait(1.0)
                CORE.DW_DrippingCum_Spell.cast( actors[0] )
              endif
            endif
          endif
        endif
      endif
    endif

  ;disabled since idk how to align ejaculation effect with penis
  ;idx = 0
  ;While idx < actors.Length
  ;	if CORE.SOS.GetSOS(akActor) == true
  ;		CORE.DW_DrippingSOSCum_Spell.cast( akActor )
  ;	endif
  ;	idx += 1
  ;EndWhile
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