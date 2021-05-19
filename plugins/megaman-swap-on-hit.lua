--[[
	This plugin is designed for Megaman 1-6 NES. The game swaps any time
	Megaman takes damage. Checks SHA-1 hashes of different rom versions, so if
	you use a version of the rom that isn't recognized, nothing special will
	happen in that game (no swap on hit). This means other games can be mixed in
--]]

plugin_game_info = {}

function checkHealthLives(data, currhp, currlc, maxhp, minhp)
	-- retrieve previous health and lives before backup
	local prevhp = data.prevhp
	local prevlc = data.prevlc

	-- backup current health and lives
	data.prevhp = currhp
	data.prevlc = currlc

	-- health must be within an acceptable range to count
	-- ON ACCOUNT OF ALL THE GARBAGE VALUES BEING STORED IN THESE ADDRESSES
	if prevhp ~= nil and currhp < prevhp
		and currhp >= minhp and currhp <= maxhp
		and prevhp >= minhp and prevhp <= maxhp then
			return true
	end

	-- check to see if the life count went down
	if prevlc ~= nil and currlc < prevlc then
		return true
	end

	-- continue
	return false
end

function _standardHealthLives(addr_hp, addr_lc, maxhp, minhp)
	return function(data)
		local currhp = mainmemory.read_u8(addr_hp)
		local currlc = mainmemory.read_u8(addr_lc)
		return checkHealthLives(data, currhp, currlc, maxhp, minhp)
	end
end

-- mmx seems to use LMB as a one-frame rise to indicate damage was taken
function _mmxHealthLives(addr_hp, addr_lc, addr_maxhp)
	return function(data)
		local currhp = bit.band(mainmemory.read_u8(addr_hp), 0x7F)
		local currlc = mainmemory.read_u8(addr_lc)
		local maxhp = mainmemory.read_u8(addr_maxhp)
		return checkHealthLives(data, currhp, currlc, maxhp, 0)
	end
end

function _signedHealthLives(addr_hp, addr_lc, maxhp, minhp)
	return function(data)
		local currhp = mainmemory.read_u8(addr_hp)
		local currlc = mainmemory.read_s8(addr_lc)
		return checkHealthLives(data, currhp, currlc, maxhp, minhp)
	end
end

_gamemeta = {
	['mm1nes']={ swapMethod=_standardHealthLives(0x006A, 0x00A6, 28, 0) },
	['mm2nes']={ swapMethod=_standardHealthLives(0x06C0, 0x00A8, 28, 0) },
	['mm3nes']={ swapMethod=_standardHealthLives(0x00A2, 0x00AE, 156, 128) },
	['mm4nes']={ swapMethod=_standardHealthLives(0x00B0, 0x00A1, 156, 128) },
	['mm5nes']={ swapMethod=_standardHealthLives(0x00B0, 0x00BF, 156, 128) },
	['mm6nes']={ swapMethod=_standardHealthLives(0x03E5, 0x00A9, 27, 0) },

	['mmx1']={ swapMethod=_mmxHealthLives(0x0BCF, 0x1F80, 0x1F9A) },
	['mmx2']={ swapMethod=_mmxHealthLives(0x09FF, 0x1FB3, 0x1FD1) },
	['mmx3']={ swapMethod=_mmxHealthLives(0x09FF, 0x1FB4, 0x1FD2) },

	['mm1gb']={ swapMethod=_signedHealthLives(0x1FA3, 0x0108, 152, 0) },
	['mm2gb']={ swapMethod=_signedHealthLives(0x0FD0, 0x0FE8, 152, 0) },
	['mm3gb']={ swapMethod=_signedHealthLives(0x1E9C, 0x1D08, 152, 0) },
	['mm4gb']={ swapMethod=_signedHealthLives(0x1EAE, 0x1F34, 152, 0) },
	['mm5gb']={ swapMethod=_signedHealthLives(0x1E9E, 0x1F34, 152, 0) },
}

-- same RAM maps across versions?
_rominfo = {
	-- Mega Man NES rom hashes
	['0FE255649359ECE8CB64B6F24ACAF09F17AF746C'] = 'mm1nes', -- Mega Man (E) [!].nes
	['17730D3A6E4A618CF1AA106024C8FB4EE2E18907'] = 'mm1nes', -- Mega Man (E) [T+Dut1.0_Ok Impala!].nes
	['6F6C21598A417CC3AD6D06D32CAB7372F12C1C7C'] = 'mm1nes', -- Mega Man (E) [T+Ita][b1].nes
	['8F4E5FCF4E8F000F47A24E8027983CE43025CD19'] = 'mm1nes', -- Mega Man (U) [b1].nes
	['434BB2FE2D0C304FF61B6443092DF80F1D9851BF'] = 'mm1nes', -- Mega Man (U) [b1][o1].nes
	['EC670DF183987A6F8E7C79818C6F09F7A5DFE7D8'] = 'mm1nes', -- Mega Man (U) [b2].nes
	['11E6F4F20056EC4D793927ECBA12C674DE88A28E'] = 'mm1nes', -- Mega Man (U) [b2][o1].nes
	['4BF1D3206AB23CE4CA4B34ACC75306DF4C0D624F'] = 'mm1nes', -- Mega Man (U) [b3].nes
	['8E631414EDE6EDD08A80A498DCEFAB74721202F5'] = 'mm1nes', -- Mega Man (U) [b4].nes
	['D4BD832BBA92B3A4E6185C9873E750432F7252A4'] = 'mm1nes', -- Mega Man (U) [h1].nes
	['CC81DF2E05333C4E5E9C12B34B3119332CB99F4D'] = 'mm1nes', -- Mega Man (U) [o1].nes
	['4C7C9BFABB2C3917DF1AC0E4412D69C0CC1FEE5B'] = 'mm1nes', -- Mega Man (U) [o2].nes
	['5580D11FE8D219CB6FECF6A33D16BF7C71319FE3'] = 'mm1nes', -- Mega Man (U) [T+Dut].nes
	['74D23553FC084C3213A44AE9A010922A39DA9CB4'] = 'mm1nes', -- Mega Man (U) [T+FreBeta(w-BossNames)_Generation IX].nes
	['B8FBE2442D662837F4CDA27426915628A51B67C5'] = 'mm1nes', -- Mega Man (U) [T+FreBeta_Generation IX].nes
	['2439681F1E7109DC8FD48F67B909293FD28F6A7F'] = 'mm1nes', -- Mega Man (U) [T+Fre_Terminus].nes
	['6702B493B63D7973EF2AE0D54B03AB20DD233B21'] = 'mm1nes', -- Mega Man (U) [T+Ger.90].nes
	['258D5BD4174EAD09635B540710987B1E61A03358'] = 'mm1nes', -- Mega Man (U) [T+Ita1.1NC_Clomax Dominion].nes
	['8E0FEC0875F99036975B877A45CD37E8EC762783'] = 'mm1nes', -- Mega Man (U) [T+Ita1.1_Clomax Dominion].nes
	['9FE9B4DB70AD1FAE13CEA4F7C8AA4DE2B0D916E4'] = 'mm1nes', -- Mega Man (U) [T+Nor0.90_Just4fun].nes
	['79BEA544EA2E9DC16504248B629378BCDECA9582'] = 'mm1nes', -- Mega Man (U) [T+Spa100%_Tanero].nes
	['FCCD92578A53C191B91AEAF9D3C09AB3F606B351'] = 'mm1nes', -- Mega Man (U) [T+Spa_PaladinKnights].nes
	['714F069E1847BA30F525AF4B8E10A8EEEBEBDA70'] = 'mm1nes', -- Mega Man (U) [T-Ita1.00_Clomax_Dominion].nes
	['F0CC04FBEBB2552687309DA9AF94750F7161D722'] = 'mm1nes', -- Mega Man (U).nes
	['2F88381557339A14C20428455F6991C1EB902C99'] = 'mm1nes', -- Mega Man (USA) No-Intro: Nintendo Entertainment System (v. 20180803-121122)
	['216B87986FF4B8A87D4501702C73DA29ED688B81'] = 'mm1nes', -- Rockman (J) [b1].nes
	['C76C565B814938DF4985E6BAAC1FE0D6CF5EE282'] = 'mm1nes', -- Rockman (J) [b2].nes
	['324A6D98BA416D1827679ABF0D241D684E0191F7'] = 'mm1nes', -- Rockman (J) [b3].nes
	['3C7674C08122F15F26EEC595922CFF8C31A8127D'] = 'mm1nes', -- Rockman (J) [b4].nes
	['81A321025700417878B8DFAA2DA97ADA1F05E57F'] = 'mm1nes', -- Rockman (J) [b5].nes
	['F6908E935FFF9768F356D9C0C8824F17CBDA622C'] = 'mm1nes', -- Rockman (J) [o1].nes
	['7B2C88D141C50B43B2A56440C6D5B35AD0B0DD5B'] = 'mm1nes', -- Rockman (J) [p1].nes
	['B105577C3E9B1DA9A41C9E0570EEC19756491F23'] = 'mm1nes', -- Rockman (J) [T+Spa_PaladinKnights].nes
	['5914D409EA027A96C2BB58F5136C5E7E9B2E8300'] = 'mm1nes', -- Rockman (J).nes
	-- Mega Man 2 NES rom hashes
	['A9DAFF94A800625A5D10345C3A3C8952FB57CF87'] = 'mm2nes', -- Mega Man 2 (E) [!].nes
	['5211852176C0EFA90705A46553A4D8AFFD1E7FEE'] = 'mm2nes', -- Mega Man 2 (U) [h1].nes
	['BA1A9D0CDD96FF0AB3BBF4873D45372F15A8D6CA'] = 'mm2nes', -- Mega Man 2 (U) [o1].nes
	['9CC6FDB1714997A9EB108E00D18E849AD6B84B13'] = 'mm2nes', -- Mega Man 2 (U) [o1][T-Ger][a1].nes
	['DD47E1B29161BC37B5AC144335C2FD9C71C72B8D'] = 'mm2nes', -- Mega Man 2 (U) [o2].nes
	['4581C42B18715C46459D5AF7B8714B1C0A186F37'] = 'mm2nes', -- Mega Man 2 (U) [T+Fre1.0].nes
	['F58025EA53D969B32910D80988232B7AB45B9BF3'] = 'mm2nes', -- Mega Man 2 (U) [T+FreBeta(w-BossNames)_Generation IX].nes
	['99E03963EDA39ECDA1B22FD358F508C39DAE8DD8'] = 'mm2nes', -- Mega Man 2 (U) [T+FreBeta_Generation IX].nes
	['9C516B275BAE5258B628A28E0EBC145188290CEB'] = 'mm2nes', -- Mega Man 2 (U) [T+Ger1.01].nes
	['5C366EF09F0B6DA755BDDBD4EEAA86C5CEDF1F62'] = 'mm2nes', -- Mega Man 2 (U) [T+Ita1.0_NukeTeam].nes
	['A0620C6656EB37D26E3D94867551CB47B59A9F72'] = 'mm2nes', -- Mega Man 2 (U) [T+Ita1.2_Clomax Dominion].nes
	['8124EE7D96ED590455C3D9FC057148B66A3F4F84'] = 'mm2nes', -- Mega Man 2 (U) [T+Nor.99_Just4fun].nes
	['C55766178B220B1B7359EBBA076F7082550D2FE1'] = 'mm2nes', -- Mega Man 2 (U) [T+Por].nes
	['9C3215806B15D95D72A43D5F48FBA3C56C02C5F1'] = 'mm2nes', -- Mega Man 2 (U) [T+Spa100%_PaladinKnights].nes
	['4B92B3143D96C643247201EC45F3D09D5520EB45'] = 'mm2nes', -- Mega Man 2 (U) [T+Spa100%_Tanero].nes
	['E3F5A07FD589F2CFBEAF448C3918529C6FAAF76C'] = 'mm2nes', -- Mega Man 2 (U) [T+Swe1.0_TheTranslator].nes
	['E73AF24C9217BD0859763607435090EDE8FBD74D'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger].nes
	['6B33095E264C96DBFB23A01CDB4A097BAF12C73F'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger][a1].nes
	['F5A1DE05C0C705D927C5D82608837B0BA9D377AD'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger][a2].nes
	['5AA5C379DB872EE8652DA03287CDE1026D4DD646'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger][b1].nes
	['98D5DB1CD22E1C06F574B099BA9C5E10DF09EE69'] = 'mm2nes', -- Mega Man 2 (U) [T-Ser0.60_SeeGot].nes
	['6B5B9235C3F630486ED8F07A133B044EAA2E22B2'] = 'mm2nes', -- Mega Man 2 (U).nes
	['2290D8D839A303219E9327EA1451C5EEA430F53D'] = 'mm2nes', -- Mega Man 2 (USA) (No-Intro version 20130731-235630)
	['A2A7B4F177CC2DEA0D846B1190008AAD3CDD45EA'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [b1].nes
	['EEA7BB60E139C96569F7CE6DBB7EB9C4ED7A655C'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [b2].nes
	['0422AB933D32C6FE39649C67B64AAE50E32ACFAF'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [o1].nes
	['7728A67FA7A8E6746E82C3591E56A3F971182275'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [o1][T+Eng1.0_AGTP].nes
	['E3B33700FE0B69F0F5D0B827AAC9EC0F9391BD66'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [p1].nes
	['E7E6C7976E54F1A91B504BE40DA915132D72130A'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [T+Chi].nes
	['3BA422AB145BE22F72836DF76BCA3844ACB6422B'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [T+Eng1.0_AGTP].nes
	['CAFCC9228DDB3C087DC393D01C8341DCC2F01588'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [T-Eng.9_AGTP].nes
	['108118F41E4CD9E375249D3A3B37A7360024FE64'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J).nes
	['FB51875D1FF4B0DEEE97E967E6434FF514F3C2F2'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (Japan).nes - NOINTRO
	-- Mega Man 3 NES rom hashes
	['4B672D13BC9B5C4267830E2B24A4CD2ACB116FAA'] = 'mm3nes', -- Mega Man 3 (Europe) (Rev A).nes
	['4651BEC411550C237DC38950A649A22430ECB169'] = 'mm3nes', -- Mega Man 3 (PC10) [!].nes
	['70B2A67921BF2133051ED987BAD98E427970F165'] = 'mm3nes', -- Mega Man 3 (U) (Prototype) [!].nes
	['53197445E137E47A73FD4876B87E288ED0FED5C6'] = 'mm3nes', -- Mega Man 3 (U) [!].nes
	['0728DB6B8AABF7E525D930A05929CAA1891588D0'] = 'mm3nes', -- ??
	['B670B3236BB60C454E3C8712B15A08DB1E31CAA3'] = 'mm3nes', -- Mega Man 3 (U) [b1].nes
	['BB8570022A40778C1410C10167203F5E9786799D'] = 'mm3nes', -- Mega Man 3 (U) [b2].nes
	['39B25C7E907C27E0801FB7AEEF193244979FD9AF'] = 'mm3nes', -- Mega Man 3 (U) [b3].nes
	['CDF9BFAFCF77CA78936D736CED8B2E54372D8F86'] = 'mm3nes', -- Mega Man 3 (U) [o1].nes
	['5AAD27B4ADA65C4189065072A24F1FE06A4B68BB'] = 'mm3nes', -- Mega Man 3 (U) [T+FreBeta(w-BossNames)_Generation IX].nes
	['0BC52C6AA273519FF04E8BFA10CF3BD02DA24F40'] = 'mm3nes', -- Mega Man 3 (U) [T+FreBeta_Generation IX].nes
	['7E9AD0FF44209E05FBC4059C00E3355D20701AE6'] = 'mm3nes', -- Mega Man 3 (U) [T+Fre_Sstrad].nes
	['07517C8C3014A73050E304B306F0995A2D1934C3'] = 'mm3nes', -- Mega Man 3 (U) [T+Ita1.0_Vecna].nes
	['80CEC685078E746D9577930391FC345B83D88DC2'] = 'mm3nes', -- Mega Man 3 (U) [T+Por].nes
	['8D39A8643187220656F01AFA3FF698C3CB176C83'] = 'mm3nes', -- Mega Man 3 (U) [T+Spa90%_PaladinKnights].nes
	['231B5E514C254B222EC6F74D7C74F4959A4D431E'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [b1].nes
	['030874B201B8A06BA215141093CFAC1C9B9E880D'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [h1].nes
	['6E42C75706A331D961A57F270DE0D14AC45CC29C'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [hFFE][b1].nes
	['104D7C8BAE79670A0C05DF9994D3FC6E52086114'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [o1].nes
	['CF11E88D6DA9F6EAC660F8858A7F5F4B28E442CB'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1].nes
	['36B501FFE32934BB83E23E6860C1B6C71E40A8E1'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b1].nes
	['ECDCABB538AF31E01E8362E3FA7FA3436A3D1B94'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b2].nes
	['C359DA8F3753B635FBE7550327DA7D15CA17BE17'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b3].nes
	['F72B44B4648E62C7DE13F9FD5AB41B03AFFBA109'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b4].nes
	['9B8A6E2E234DEB0697A8172C83AC90DEB3B209EA'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J).nes
	['E82C532DE36C6A5DEAF08C6248AEA434C4D8A85A'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [!].nes - GOODNES 3.14
	-- Mega Man 4 NES rom hashes
	['BD607BE30AF655A2F171A45E1588B5EEC45E2FAE'] = 'mm4nes', -- Mega Man 4 (E).nes
	['2AE9A049DAFC8C7577584B4B9256F7EF8932B29C'] = 'mm4nes', -- Mega Man 4 (U) [!].nes
	['F4E919FF86C82E55532F203F93047965D0602857'] = 'mm4nes', -- Mega Man 4 (U) [b1].nes
	['C68061875BBC5FD2E39E897612BDD5B0C0D0DDF0'] = 'mm4nes', -- Mega Man 4 (U) [b2].nes
	['140CBE9BBBE5CE075142BA58E85F21F59077B503'] = 'mm4nes', -- Mega Man 4 (U) [b3].nes
	['D544224ECE14A33EFB93C9C0C79C5653650653C9'] = 'mm4nes', -- Mega Man 4 (U) [b4].nes
	['9B5FC2A0195DAF6D0F495F385D21A7779B396533'] = 'mm4nes', -- Mega Man 4 (U) [o1].nes
	['BB97CB32E9731B3A67DA10C7ED33CB7540068A79'] = 'mm4nes', -- Mega Man 4 (U) [T+FreBetaBossNames_Generation IX].nes
	['01FE30810C29E288EEB2DAECB93DA35DC715683B'] = 'mm4nes', -- Mega Man 4 (U) [T+Fre_Shock].nes
	['34E31E728EB01A42EA7C45A757E06A7DB5E3F339'] = 'mm4nes', -- Mega Man 4 (U) [T+Ita1.0_Vecna].nes
	['A03405EC28D97B71445B5F9FDC8E0068973DC7C3'] = 'mm4nes', -- Mega Man 4 (U) [T+Spa100%_Chilensis].nes
	['B8C3EE6D7BE7F0807644D10CACA3C8BC54519CEB'] = 'mm4nes', -- Mega Man 4 (U) [T+Spa_Djt].nes
	['3B76DD7FCF1C7C2DBB475680B778C4136DAB7230'] = 'mm4nes', -- Mega Man 4 (U) [T-FreBeta_Generation IX].nes
	['B098BF509E2E6A4144FB592DFDEAD9E2DA6DE487'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [a1].nes
	['2D3FC452815B41D6781EC908E0A8FDF2437ED866'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b1].nes
	['AB35FEBEF989E89BFC9F7E014F8FC674E08D1726'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b2].nes
	['CAA7CAB393B87990EA7475047F6652509992529E'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b3].nes
	['781EF34750A870D1539C0FA9F37F7069FB5FF39B'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b4].nes
	['A1CB0F958EAFA1FD4C38974EEBDA122A0E28E025'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [o1].nes
	['C33C6FA5B0A5B010AF6B38CBD22252A595500A5A'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J).nes
	-- Mega Man 5 NES rom hashes
	['705BE5641C02B040FEF9F724F61D3DD2F0EF7C98'] = 'mm5nes', -- Mega Man 5 (Europe).nes
	['0A28FE72A02D8C3D71775F4D97C649E247E2A24B'] = 'mm5nes', -- Mega Man 5 (U) [b1].nes
	['42588659DF28C72B25E654A7A599FC4F9DFE5DDE'] = 'mm5nes', -- Mega Man 5 (U) [b2].nes
	['6476C9404ACA29BF011F5419CF3672070D70D342'] = 'mm5nes', -- Mega Man 5 (U) [b3].nes
	['17F81D350B4FD657102F78827B1B10D499F6E600'] = 'mm5nes', -- Mega Man 5 (U) [b4].nes
	['19EAC3E489660EB1EA3AA8BE4FEEB5C53364E94D'] = 'mm5nes', -- Mega Man 5 (U) [b5].nes
	['2B1B4ED94EBC32314930D646F576CBD708C4FAB8'] = 'mm5nes', -- Mega Man 5 (U) [b6].nes
	['7C5802E3ED945064E0132F539E243241688D9ABB'] = 'mm5nes', -- Mega Man 5 (U) [b7].nes
	['338C5A871DA81A302EB84319D5416BFFC08FAA7B'] = 'mm5nes', -- Mega Man 5 (U) [h1].nes
	['3CF7F6329FF510DC42CD6AC07060A0B185BFB9F7'] = 'mm5nes', -- Mega Man 5 (U) [o1].nes
	['3E1E5AB6A3A447F5D2C3455B008D53DB85F24C97'] = 'mm5nes', -- Mega Man 5 (U) [T+FreBetaBossNames_Generation IX].nes
	['E43A356C6166550CF0C2E66AAA9F235DA69D6E6A'] = 'mm5nes', -- Mega Man 5 (U) [T+Fre_Nanard].nes
	['A2B370AA820B06A5CA37070A78E49F1EA82B4055'] = 'mm5nes', -- Mega Man 5 (U) [T+Ita1.0_Vecna].nes
	['6C281843BE12690F97E88D89A1DC426CAD01798F'] = 'mm5nes', -- Mega Man 5 (U) [T+Nor0.90a_Just4fun].nes
	['B715974F7462B8C34C17EDEB83FBA8307273B183'] = 'mm5nes', -- Mega Man 5 (U) [T+Spa_Chilensis].nes
	['94A29041A587CADD80A5117B7F420333F02B8003'] = 'mm5nes', -- Mega Man 5 (U) [T-FreBeta_Generation IX].nes
	['1748E9B6ECFF0C01DD14ECC7A48575E74F88B778'] = 'mm5nes', -- Mega Man 5 (U).nes
	['EB9CF42546D82DEC4786B9008032E9019085E7DF'] = 'mm5nes', -- Rockman 5 - Blues no Wana! (J) [b1].nes
	['E9A22F737235857B01BE6DB3C10259565AFDDF49'] = 'mm5nes', -- Rockman 5 - Blues no Wana! (J) [o1].nes
	['0FC06CE52BBB65F6019E2FA3553A9C1FC60CC201'] = 'mm5nes', -- Rockman 5 - Blues no Wana! (J).nes
	-- Mega Man 6 NES rom hashes
	['1992CB26421BD13B5770244767F4F49F1E85410D'] = 'mm6nes', -- Mega Man 6 (U) [b1].nes
	['A4BF996782528C3D810966CA7F390EFBC30D909B'] = 'mm6nes', -- Mega Man 6 (U) [b1][T+Swe1.0_TheTranslator].nes
	['E9DF03297E1D43986F568BF6617B2C1B32F4336D'] = 'mm6nes', -- Mega Man 6 (U) [b2].nes
	['D9347FFAE8E1C6921FAB27BFE48D640990C6AC24'] = 'mm6nes', -- Mega Man 6 (U) [b3].nes
	['0C9BB9EDF8BE980A862CD9DCE3F89BC5724F0AE0'] = 'mm6nes', -- Mega Man 6 (U) [b4].nes
	['DF6878829444F0B9BACB5C84866B9BB16E737B77'] = 'mm6nes', -- Mega Man 6 (U) [b5].nes
	['0FB233A2262028F6F6460932989BC6BFBC7EE51E'] = 'mm6nes', -- Mega Man 6 (U) [b6].nes
	['0B3ECE5187DE5EDD45D7D0BA814CE5F046D13EBD'] = 'mm6nes', -- Mega Man 6 (U) [b7].nes
	['B4462E4A741047A85E30E97DF86CE7E8CCCAAA6A'] = 'mm6nes', -- Mega Man 6 (U) [b8].nes
	['9B26586C1F562DF2FD91FD5D8D6743D6D8F07CCB'] = 'mm6nes', -- Mega Man 6 (U) [h1].nes
	['B6A4E916815C91E95B7474467D487861CC2693B9'] = 'mm6nes', -- Mega Man 6 (U) [o1].nes
	['A17F720294AC3CA0945BC034B9127A7F2936BD04'] = 'mm6nes', -- Mega Man 6 (U) [T+FreBeta2BossNames_Generation IX].nes
	['733BB196D5DC2E68EFA1D26001D36A53233101B2'] = 'mm6nes', -- Mega Man 6 (U) [T+Fre].nes
	['4EE2F554F2DFBB6E5496E3AE32997C1D75F95B1A'] = 'mm6nes', -- Mega Man 6 (U) [T+Fre_Nanard].nes
	['F786DD6097E068B3B3F3AF28E84BE607415BBAAD'] = 'mm6nes', -- Mega Man 6 (U) [T+Ger1.01].nes
	['376A2AD0B744542585FDAF7CE67FE45458931124'] = 'mm6nes', -- Mega Man 6 (U) [T+Ita1.0_Vecna].nes
	['E1B002B786B8AFAE2A4AC2C6AAF926F92574D51A'] = 'mm6nes', -- Mega Man 6 (U) [T+Nor1.00_Just4Fun].nes
	['E63BF1959C13E514D701C7E77342743C528D8797'] = 'mm6nes', -- Mega Man 6 (U) [T+Por].nes
	['B99ED19876B89004135D4207C098FC3BD9698E4F'] = 'mm6nes', -- Mega Man 6 (U) [T+Spa_Djt].nes
	['DFF827693E1BEF6D78026F6D1C3DC87EDA4FEBC7'] = 'mm6nes', -- Mega Man 6 (U) [T+Swe1.0_TheTranslator].nes
	['EE4B84CDEA7FAFE3E17FEF540DC6DC398D4FBEE5'] = 'mm6nes', -- Mega Man 6 (U) [T-FreBeta2_Generation IX].nes
	['3CD17C90A4577D426DCA7DDFA4A9AF4980D6EAE0'] = 'mm6nes', -- Mega Man 6 (U) [T-FreBetaBossNames_Generation IX].nes
	['0EFFE2E3E2B09BA3AD5E4225ACB6988B9BF829EF'] = 'mm6nes', -- Mega Man 6 (U) [T-FreBeta_Generation IX].nes
	['32774F6A0982534272679AC424C4191F1BE5F689'] = 'mm6nes', -- Mega Man 6 (U).nes
	['6E0C56F13188E967427B656D5DCAFE4884C6D518'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J) [o1].nes
	['DB303209E934BD1111C3FB1CF253F43F4DE0AB73'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J) [o1][T+Chi].nes
	['17CE145137DD6D3FFEAE3FBBC3E47E4D3D69E6B2'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J) [T+Chi].nes
	['DD95FAF3FC64BFAF8B8FE2160F2721E1900E1361'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J).nes
	-- Mega Man X SNES rom hashes
	['8A32570FAD3BFC92C0508C88022FB20412DD7BED'] = 'mmx1', -- Mega Man X (E).smc
	['449A00631208FBCC8D58209E66D0D488674B7FB1'] = 'mmx1', -- Mega Man X (U) (V1.0) [!].smc
	['E8921E243394B03382C03A6A08054F490C8F3DC8'] = 'mmx1', -- Mega Man X (U) (V1.0) [f1].smc
	['13D3730F56E5F1365869C9D933F956592DBAE2CC'] = 'mmx1', -- Mega Man X (U) (V1.0) [f1][T+Por].smc
	['BD00A9799A5B50782334F8165BAD28C215C64FCE'] = 'mmx1', -- Mega Man X (U) (V1.0) [f2].smc
	['241E79805B679907004F2023A100DADECB9EC2CC'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Catalan].smc
	['0A66ACAE238D3CD5D237AD0F2614F253558D2B0B'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Fre.1_BessaB].smc
	['4AA221EB70DF6E0140506DE3FB4EAE72CA762248'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Fre].smc
	['1E1E55CC3B2A012F97ABB3FEA42F5E5766B1C42E'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Ger100%_TranX].smc
	['EA77D11BAFBB73B72CE7789910DD7BA70952A585'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Ita1.10_Clomax].smc
	['7CC9BB9FBC3AC9CDA039D18FF3E05D8E15AB764B'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Por].smc
	['F219D1EF0CBE49780B0D6C332A99B4AA66924AA0'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Spa099_Ereza].smc
	['EFEA5FBE9B161219175CCBFF4B41BCED5E470B5F'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Spa100_Tanero].smc
	['ADBBC837DB8A98071C4AE1867B2CB878A2BA8EC0'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Spa100_Windfish].smc
	['CA578B24C7E4E37637F6093905F861643D234CB5'] = 'mmx1', -- Mega Man X (U) (V1.0) [T-Ita].smc
	['56A26EDC7234E93921AF3D8A04EABE5916008DED'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Catalan].smc
	['E223EC424D5936F3B884265D7BC865D43DE58A7F'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Ger.99_g-trans(sephiroth)].smc
	['16A0246A5B769DB68B07F8FE7244ACBA18938917'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Ita1.10_Clomax].smc
	['A521187ADB03B37B5B5FC57BE0D65AED9FE7840D'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Spa099_Ereza].smc
	['17B58BAC499ECBC8A92B8A346C6C12DDB8A4DABE'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Spa100%_Windfish].smc
	['7433124B6BDE8B002FA6493F29C56C01AC382D7A'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Spa100_Tanero].smc
	['C65216760BA99178100A10D98457CF11496C2097'] = 'mmx1', -- Mega Man X (U) (V1.1).smc
	['86C18BA1FC762B6D0BCDEE7314A29B5C97CAC082'] = 'mmx1', -- Rockman X (J) (V1.0) [!].smc
	['870F1FADBB8D2BEC1C2B73B9635473BC58C6415E'] = 'mmx1', -- Rockman X (J) (V1.0) [h1].smc
	['03F8F99D27874465F8D3E5EC9628927AC5BE6FAE'] = 'mmx1', -- Rockman X (J) (V1.1).smc
	-- Mega Man X2 SNES rom hashes
	['5C767285DA713DE2BC883A6291D32ADC9B2D13FA'] = 'mmx2', -- Mega Man X 2 (E) [!].smc
	['E5893F23A7C04036EF3D54E09B98FD1C983362BA'] = 'mmx2', -- Mega Man X 2 (E) [b1].smc
	['FD3BFBEF32DBB01DA2BA11CD59AD773D29A04960'] = 'mmx2', -- Mega Man X 2 (U) [b1].smc
	['E3160744BE80529152247379FB1BDBAA83569C38'] = 'mmx2', -- Mega Man X 2 (U) [o1].smc
	['BDB22B8DCB1D05BD0AE0637E90C0761F213D3631'] = 'mmx2', -- Mega Man X 2 (U) [o1][T+Ger100%_alemanic].smc
	['FB09794E161425A6D614CE1ECA84247AC895CFBD'] = 'mmx2', -- Mega Man X 2 (U) [o1][T+Ger100%_TranX].smc
	['36A332D0FB8759B4E1D98EFDB9757E22036ABB67'] = 'mmx2', -- Mega Man X 2 (U) [T+Ger100%_alemanic].smc
	['84ED9FFD6ADE34715B48D56B163889BF527923A6'] = 'mmx2', -- Mega Man X 2 (U) [T+Ita091_Clomax].smc
	['CD3E544C46CBDE55FD93684F7ABD5CCE9BDD9667'] = 'mmx2', -- Mega Man X 2 (U) [T+Por].smc
	['6E21A0A090C40C5E952F083D703A80F69BD97BF8'] = 'mmx2', -- Mega Man X 2 (U) [T+Spa050_Pkt].smc
	['A974F8940088B1D49E85EC42129C32B420AD688E'] = 'mmx2', -- Mega Man X 2 (U) [T+Spa101_Ereza].smc
	['637079014421563283CDED6AEAA0604597B2E33C'] = 'mmx2', -- Mega Man X 2 (U).smc
	['1A0529685D1AF13F5AF209A8A297832AE433DBCD'] = 'mmx2', -- Rockman X 2 (J) [o1].smc
	['34DC37C8A1905EC5631FA666EBA84BB78F9C5BDF'] = 'mmx2', -- Rockman X 2 (J).smc
	-- Mega Man X3 SNES rom hashes
	['69A11324AEB57D005800771D6147603D5479B282'] = 'mmx3', -- Mega Man X 3 (E) [!].smc
	['F320F4C9FC9E5CC866D899FED8B300111E41D2D7'] = 'mmx3', -- Mega Man X 3 (E) [b1].smc
	['E73BED2D65297F3685F1B74287FCA4D42602BF3B'] = 'mmx3', -- Mega Man X 3 (U) [T+Fre].smc
	['0A4438B210EE705F8803CF466A382827A43CD84E'] = 'mmx3', -- Mega Man X 3 (U) [T+Ger100%_TranX].smc
	['C058FF30989B8BB8B475BEEDB797DD7841F72ECC'] = 'mmx3', -- Mega Man X 3 (U) [T+Ita].smc
	['A35EE942D8F7B5893E0BCF2426E439836A4AD27D'] = 'mmx3', -- Mega Man X 3 (U) [T+Por].smc
	['7DCD0FD1EF2CBED1EBF56C3999B37B8C5DF0C69F'] = 'mmx3', -- Mega Man X 3 (U) [T+Spa100_Tanero].smc
	['BF8CE9F1EF4756AE4091D938AC6657DD3EFFB769'] = 'mmx3', -- Mega Man X 3 (U) [T+Swe1.0_GCT].smc
	['B226F7EC59283B05C1E276E2F433893F45027CAC'] = 'mmx3', -- Mega Man X 3 (U).smc
	['8E0156FC7D6AF6F36B08A5E399C0284C6C5D81B8'] = 'mmx3', -- Rockman X 3 (J).smc
	-- Mega Man GB rom hashes
	['277EDB3C844E812BA4B3EB9A96C9C30414541858'] = 'mm1gb', -- Mega Man (U) [!].gb
	['334F1A93346D55E1BE2967F0AF952E37AA52FCA7'] = 'mm2gb', -- Mega Man 2 (U) [!].gb
	['57347305AB297DAA4332564623C4A098E6DBB1A3'] = 'mm3gb', -- Mega Man 3 (U) [!].gb
	['A1FF192436BCBFC73CB58E494976B0EA6CD45D16'] = 'mm3gb', -- Mega Man 3 (U) [t1].gb
	['6F0901DB2B5DCAACE0215C0ABDC21A914FA21B65'] = 'mm4gb', -- Mega Man 4 (U) [!].gb
	['9A7DA0E4D3F49E4A0B94E85CD64E28A687D81260'] = 'mm5gb', -- Mega Man 5 (U) [S][!].gb
}

function on_game_load(data)
	local whichgame = _rominfo[gameinfo.getromhash()]
	if whichgame == nil then
		print('unrecognized hash for ' .. gameinfo.getromname() .. ': ' .. gameinfo.getromhash())
	end
end

-- called each frame
function on_frame(data)
	-- do we recognize this game?
	local whichgame = _rominfo[gameinfo.getromhash()]
	if whichgame == nil then return end

	-- run the check method for each individual game
	local meta = _gamemeta[whichgame]
	if meta.swapMethod(plugin_game_info) and frames_since_restart > 10 then
		swap_game_delay(5)
	end
end
