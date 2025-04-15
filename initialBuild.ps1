function New-Character{
    param (
        [string] $characterName,
        [boolean] $allied,
        [float] $initiative,
        [UInt16] $ac,
        [UInt16] $currentHp,
        [UInt16] $maxHP
    )

    $characterJson = @{
        characterName = "$characterName"
        allied = $allied
        activePlayer = $false
        initiative = $initiative
        ac = $ac
        currentHp = $currentHp
        maxHp = $maxHP
        hpPercent = [Math]::Round(($currentHp / $maxHP) * 100)
        status = @()
    }

    return $characterJson
}

function New-Status {
    param (
        [string] $statusName,
        [UInt16] $duration,
        [string] $effect
    )

    $statusJson = @{
        statusName = "$statusName"
        duration = $duration
        effect = $effect
    }

    return $statusJson    
}

# Create Base JSON Values
$EncounterJson = @{
    characters = @()
}

New-UDApp -Content {
    New-UDGrid -Container -Content {
        New-UDGrid -Item -ExtraSmallSize 12 -Content {
            New-UDTypography -Text "Encounter Tracker" -Variant h2 -Align center
            New-UDDataGrid -PageSize 50 -DefaultSortColumn initiative -DefaultSortDirection desc -StripedRows -LoadRows {
                $EncounterJson.characters | Out-UDDataGridData -Context $EventData -TotalRows ($EncounterJson.characters).Length
            } -Columns @(
                New-UDDataGridColumn -Field activePlayer -HeaderName "TURN" -Flex 1 -Render {
                    if ($EventData.activePlayer -eq $true){
                        New-UDChip -Icon (New-UDIcon -Icon 'CheckSquare' -Color "Green" -Solid -Size md)
                    }
                    else {
                        New-UDChip -Icon (New-UDIcon -Icon 'Clock' -Size md) -OnClick  {
                            Show-UDToast -Message 'Changing Active Turn'
                            $EncounterJson.characters | Where-Object { $_.activePlayer -eq $true } | ForEach-Object {
                                $_.activePlayer = $false
                            }
                            $EncounterJson.characters | Where-Object { $_.characterName -eq $EventData.charactername } | ForEach-Object {
                                $_.activePlayer = $true
                            }
                            Invoke-UDRedirect -Url "/"
                        }
                    }
                }
                New-UDDataGridColumn -Field characterName -HeaderName "CHARACTER" -Flex 5 -Render {
                    if ($EventData.allied -eq $true){
                        New-UDChip -Label "`t$($EventData.characterName)" -Icon (New-UDIcon -Icon 'User' -Color "Green" -Solid -Size md)
                        <#
                         -OnClick  {
                            Show-UDToast -Message 'Changing Allied Status'
                            $EncounterJson.characters | Where-Object { $_.characterName -eq $EventData.charactername } | ForEach-Object {
                                $_.allied = $false
                            }
                        }
                        #>
                    }
                    else {
                        New-UDChip -Label "`t$($EventData.characterName)" -Icon (New-UDIcon -Icon 'User' -Color "Red" -Solid -Size md)
                    }
                }
                New-UDDataGridColumn -Field initiative -HeaderName "INITIATIVE" -Flex 2 -Editable
                New-UDDataGridColumn -Field ac -HeaderName "AC" -Flex 2 -Editable
                New-UDDataGridColumn -Field currentHp -HeaderName "CURRENT HP" -Flex 2 -Editable
                New-UDDataGridColumn -Field maxHp -HeaderName "MAX HP" -Flex 2 -Editable
                New-UDDataGridColumn -Field hpPercent -HeaderName "HP PERCENT" -Flex 2 -Render {
                    if ($EventData.hpPercent -ge 80){
                        New-UDChip -Label "`t$($EventData.hpPercent) %" -Icon (New-UDIcon -Icon 'Heartbeat' -Color "Green" -Solid -Size md)
                    }
                    if (($EventData.hpPercent -ge 50) -and ($EventData.hpPercent -lt 80)){
                        New-UDChip -Label "`t$($EventData.hpPercent) %" -Icon (New-UDIcon -Icon 'Heartbeat' -Color "Aqua" -Solid -Size md)
                    }
                    if (($EventData.hpPercent -ge 25) -and ($EventData.hpPercent -lt 50)){
                        New-UDChip -Label "`t$($EventData.hpPercent) %" -Icon (New-UDIcon -Icon 'Heartbeat' -Color "Yellow" -Solid -Size md)
                    }
                    if (($EventData.hpPercent -gt 0) -and ($EventData.hpPercent -lt 25)){
                        New-UDChip -Label "`t$($EventData.hpPercent) %" -Icon (New-UDIcon -Icon 'HeartBroken' -Color "Red" -Solid -Size md)
                    }
                    if ($EventData.hpPercent -eq 0){
                        New-UDChip -Label "`t$($EventData.hpPercent) %" -Icon (New-UDIcon -Icon 'SkullCrossbones' -Solid -Size md)
                    }
                }
                New-UDDataGridColumn -Field remove -HeaderName "REMOVE" -Flex 1  -Render {
                    New-UDChip -Icon (New-UDIcon -Icon 'Trash' -Solid -Size sm) -OnClick  {
                        Show-UDToast -Message 'Removing Character' -Duration 10000
                        $jsonTrim = ($EncounterJson.characters | Where-Object {$_.characterName -ne $EventData.characterName})
                        $EncounterJson.characters = $jsonTrim
                        Invoke-UDRedirect -Url "/"
                    }
                }
            ) -AutoHeight $true -Pagination -OnEdit {
                    $EncounterJson.characters | Where-Object { $_.characterName -eq $EventData.oldRow.characterName } | ForEach-Object {
                        $_.ac = $EventData.NewRow.ac
                        $_.initiative = $EventData.NewRow.initiative
                        $_.currentHp = $EventData.NewRow.currentHp
                        $_.maxHP = $EventData.NewRow.maxHP
                        $_.hpPercent = [Math]::Round(($EventData.NewRow.currentHp / $EventData.NewRow.maxHP) * 100)
                    }
            } -LoadDetailContent {
                $characterInfo = $EventData.row
                $statusCount = (($EncounterJson.characters).Where({$_.characterName -eq $characterInfo.charactername}).Status).count
                if ($statusCount -gt 0){
                    New-UDDataGrid -StripedRows -Density compact -LoadRows {
                        ($EncounterJson.characters).Where({$_.characterName -eq $characterInfo.charactername}).Status | Out-UDDataGridData -Context $EventData -TotalRows (($EncounterJson.characters).Where({$_.characterName -eq $characterInfo.charactername}).Status).count
                    } -Columns @(
                        New-UDDataGridColumn -Field statusName -Flex 2 -HeaderName "STATUS NAME" -DisableColumnMenu
                        New-UDDataGridColumn -Field duration -Flex 1 -HeaderName "DURATION" -DisableColumnMenu
                        New-UDDataGridColumn -Field effect -Flex 17 -HeaderName "EFFECT INFO" -DisableColumnMenu
                        New-UDDataGridColumn -Field remove -HeaderName "REMOVE" -DisableColumnMenu -Flex 1 -Render {
                            New-UDChip -Icon (New-UDIcon -Icon 'Trash' -Solid -Size sm) -OnClick  {
                                Show-UDToast -Message 'Removing Status' -Duration 10000
                                $jsonField = (($EncounterJson.characters).Where({$_.characterName -eq $characterInfo.charactername}).Status | Where-Object { $_.statusName -ne $EventData.statusName})
                                $EncounterJson.characters | Where-Object { $_.characterName -eq $characterInfo.charactername } | ForEach-Object {
                                    $_.status = $jsonField
                                }
                                Invoke-UDRedirect -Url "/"
                            }
                        }
                    )
                }
                else {
                    New-UDTypography -Text "No Applied Statuses to Display" -Align center
                }
            }
        }

        # New Character Form
        New-UDGrid -Item -ExtraSmallSize 3 -Content {
            $cardHeader = New-UDCardHeader -Title 'Add Character' -TitleAlignment center
            $cardBody = New-UDCardBody -Content {
                New-UDForm -Content {
                    New-UDTextbox -Id 'txtCharName' -Label 'Character Name'
                    New-UDCheckbox -Id 'chkCheckbox' -Label 'Allied Character'
                    New-UDTextbox -Id 'intAC' -Label 'AC'
                    New-UDTextbox -Id 'intInit' -Label 'Initiative'
                    New-UDTextbox -Id 'intHP' -Label 'Maximum HP'
                } -OnSubmit {
                    # Add Character to the Encounter JSON
                    $EncounterJson.characters += New-Character -characterName $EventData.txtCharName `
                        -allied $EventData.chkCheckbox `
                        -initiative $EventData.intInit `
                        -ac $EventData.intAC `
                        -currentHp $EventData.intHP `
                        -maxHP $EventData.intHP
                    
                    # Force Refresh of page
                    Invoke-UDRedirect -Url "/"
                }
            }
            New-UDCard -Header $cardHeader -Body $cardBody
        }

        # New Status Form
        New-UDGrid -Item -ExtraSmallSize 3 -Content {
            $cardHeader = New-UDCardHeader -Title 'Add Status' -TitleAlignment center
            $cardBody = New-UDCardBody -Content {
                New-UDForm -Content {
                    $charAutoComplete = @()
                    foreach ($character in $EncounterJson.characters){
                        $charAutoComplete += $character.characterName
                    }
                    New-UDAutocomplete -Id 'txtCharName' -Label 'Character Name' -Options $charAutoComplete
                    New-UDAutocomplete -Id 'txtStatusName' -Label 'Status Name' -Options @('Other', 'Blinded','Charmed', 'Concentrating', 'Deafened', 'Exhaustion', 'Frightened', 'Grappled', 'Incapacitated', 'Invisible', 'Paralyzed', 'Petrified', '
                    ', 'Prone', 'Restrained', 'Stunned', 'Unconscious')
                    New-UDTextbox -Id 'txtCustomStatusName' -Label 'Custom Status Name'
                    New-UDTextbox -Id 'txtCustomEffect' -Label 'Custom Status Effect'
                    New-UDTextbox -Id 'intDuration' -Label 'Duration'
                } -OnSubmit {

                    # HEY!!!
                    # CONVERT THIS TO A SWITCH OR A LOOKUP TABLE PLEASE!!!!
                    if (($EventData.txtCustomStatusName)){
                        $statusName = $EventData.txtCustomStatusName
                        $effect = $EventData.txtCustomEffect
                    }
                    elseif ($EventData.txtStatusName -eq 'Blinded') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A blinded creature can’t see and automatically fails any ability check that requires sight. Attack rolls against the creature have advantage, and the creature’s attack rolls have disadvantage."
                    }
                    elseif ($EventData.txtStatusName -eq 'Charmed') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A charmed creature can’t attack the charmer or target the charmer with harmful abilities or magical effects. The charmer has advantage on any ability check to interact socially with the creature"
                    }
                    elseif ($EventData.txtStatusName -eq 'Concentrating') {
                        $statusName = $EventData.txtStatusName
                        $effect = "Focusing on a Spell"
                    }
                    elseif ($EventData.txtStatusName -eq 'Deafened') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A deafened creature can’t hear and automatically fails any ability check that requires hearing."
                    }
                    elseif ($EventData.txtStatusName -eq 'Frightened') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A frightened creature has disadvantage on ability checks and attack rolls while the source of its fear is within line of sight. The creature can’t willingly move closer to the source of its fear."
                    }
                    elseif ($EventData.txtStatusName -eq 'Grappled') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A grappled creature’s speed becomes 0, and it can’t benefit from any bonus to its speed. The condition ends if the grappler is incapacitated (see the condition). The condition also ends if an effect removes the grappled creature from the reach of the grappler or grappling effect, such as when a creature is hurled away by the thunderwave spell."
                    }
                    elseif ($EventData.txtStatusName -eq 'Incapacitated') {
                        $statusName = $EventData.txtStatusName
                        $effect = "An incapacitated creature can’t take actions or reactions."
                    }
                    elseif ($EventData.txtStatusName -eq 'Invisible') {
                        $statusName = $EventData.txtStatusName
                        $effect = "An invisible creature is impossible to see without the aid of magic or a special sense. For the purpose of hiding, the creature is heavily obscured. The creature’s location can be detected by any noise it makes or any tracks it leaves. Attack rolls against the creature have disadvantage, and the creature’s attack rolls have advantage."
                    }
                    elseif ($EventData.txtStatusName -eq 'Paralyzed') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A paralyzed creature is incapacitated (see the condition) and can’t move or speak. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage. Any attack that hits the creature is a critical hit if the attacker is within 5 feet of the creature."
                    }
                    elseif ($EventData.txtStatusName -eq 'Petrified') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A petrified creature is transformed, along with any nonmagical object it is wearing or carrying, into a solid inanimate substance (usually stone). Its weight increases by a factor of ten, and it ceases aging. The creature is incapacitated (see the condition), can’t move or speak, and is unaware of its surroundings. Attack rolls against the creature have advantage. The creature automatically fails Strength and Dexterity saving throws. The creature has resistance to all damage. The creature is immune to poison and disease, although a poison or disease already in its system is suspended, not neutralized."
                    }
                    elseif ($EventData.txtStatusName -eq 'Poisoned') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A poisoned creature has disadvantage on attack rolls and ability checks."
                    }
                    elseif ($EventData.txtStatusName -eq 'Prone') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A prone creature’s only movement option is to crawl, unless it stands up and thereby ends the condition. The creature has disadvantage on attack rolls. An attack roll against the creature has advantage if the attacker is within 5 feet of the creature. Otherwise, the attack roll has disadvantage."
                    }
                    elseif ($EventData.txtStatusName -eq 'Restrained') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A restrained creature’s speed becomes 0, and it can’t benefit from any bonus to its speed. Attack rolls against the creature have advantage, and the creature’s attack rolls have disadvantage. The creature has disadvantage on Dexterity saving throws."
                    }
                    elseif ($EventData.txtStatusName -eq 'Stunned') {
                        $statusName = $EventData.txtStatusName
                        $effect = "A stunned creature is incapacitated (see the condition), can’t move, and can speak only falteringly. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage."
                    }
                    elseif ($EventData.txtStatusName -eq 'Unconscious') {
                        $statusName = $EventData.txtStatusName
                        $effect = "An unconscious creature is incapacitated (see the condition), can’t move or speak, and is unaware of its surroundings. The creature drops whatever it’s holding and falls prone. The creature automatically fails Strength and Dexterity saving throws. Attack rolls against the creature have advantage. Any attack that hits the creature is a critical hit if the attacker is within 5 feet of the creature."
                    }
                    $message = ('Adding Effect "{0}" to Character "{1}"' -f $statusName, $EventData.txtCharName)
                    $EncounterJson.characters | Where-Object { $_.characterName -eq $EventData.txtCharName } | ForEach-Object {
                        $_.status += (New-Status -statusName $statusName -duration $EventData.intDuration -effect $effect)
                    }
                    Show-UDToast -Message $message -Duration 10000
                    Invoke-UDRedirect -Url "/"
                }
            }
            New-UDCard -Header $cardHeader -Body $cardBody
        }
    }
}
