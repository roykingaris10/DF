--[[ 
	Dialogue Template w/o choices and single line text:
--------------------------------------------------------------------------------------
	['NameOfNPC'] = {
		[1] = {
			Default = {
				Text = {
					"Hi there, how you doing?"
				},
				Choices = nil
				Sound = nil,
				AnimationID = nil
			}
		}
	}
--------------------------------------------------------------------------------------

	Dialogue Template w/o choices and multiple line text:
--------------------------------------------------------------------------------------
	['NameOfNPC'] = {
		[1] = {
			Default = {
				Text = {
					"Hi there, how you doing?"
					"I am glad you spoke with me"
				},
				Choices = nil
				Sound = nil,
				AnimationID = nil
			}
		}
	}
--------------------------------------------------------------------------------------

	Dialogue Template w/ choices and single line text:
--------------------------------------------------------------------------------------
	['NameOfNPC'] = {
		[1] = {
			Default = {
				Text = {
					"Hi there, how you doing?, please select a choice"
				},
				Choices = {
					[1] = "Choice 1",
					[2] = "Choice 2"
				},
				Sound = nil,
				AnimationID = nil
			},
			['1'] = {
				Text = {
					"You selected choice 1"
				},
				Choices = nil.
				Sound = nil,
				AnimationID = nil
			}
			['2'] = {
				Text = {
					"You selected choice 2"
				},
				Choices = nil,
				Sound = nil,
				AnimationID = nil
			}	
		}
	}
--------------------------------------------------------------------------------------

	Explanation of dialogue system
	Line 37, 20 and 4 is where you are able to set the name of the NPC to refer to their dialogue. All NPC will have a unique name to call
	
	Line 38, 21, 5 represent as 1 meaning the first time you talk with that NPC the following dialogue shows up. 
	If you wanted to create multiple dialogue or dialogue that only shows up after a certain event/requirement, you would duplicate the template part of ['1']
	and include it in another table under ['1'] and rename it as ['2'], etc. [Speak to scripter for more info]
	
	The amount of lines of text inside the text tables determine how much text shows up before the choice if any. If choice is set to nil then it will end dialogue
	However if there is a choice detailed similar to the template with choices, it will give the option to choose one of the following choices available.
	To determine the next dialogue from default after a choice has been made. It will look at the column where the default conversation is set up and look for
	the number of choice. Therefore if there are two choicse and only made in default, the converstaions will be as followed: Default, ['1'], ['2'].
	If there are 2 choices in default while another 2 choices added to ['1'] and ['2'] then the amount of converstaions would be increased
	as followed: Default, ['1'], ['2'], ['11'], ['12'], ['21'], ['22']
	This is because ['11'1 replresents the first choice on both the first and second conversation and directs dialogue to whatever is inside ['11']
	For example if you decides to choose choise 1 in default and choice 2 in ['1'], the dialogue system would move dialogue to whatever conversation is set up
	in ['12']. This can go as far as you please however keep in mind complexity increases and to make sure you fill in for all options available.


--------------------------------------------------------------------------------------

]]
local DialogueDictionary = {
	--[[ EXAMPLE
	['NameOfNPC'] = {
		[1] = {
			Default = {
				Text = {
					"Hi there, how you doing?, please select a choice"
				},
				Choices = {
					[1] = "Choice 1",
					[2] = "Choice 2"
				},
				Sound = nil,
				AnimationID = nil
			},
			['1'] = {
				Text = {
					"You selected choice 1"
				},
				Choices = nil.
				Sound = nil,
				AnimationID = nil
			}
			['2'] = {
				Text = {
					"You selected choice 2"
				},
				Choices = nil,
				Sound = nil,
				AnimationID = nil
			}	
		}
	}
	]]

}


for _, folder in pairs(script:GetChildren()) do
	for _, module in pairs(folder:GetChildren()) do
		local dict = require(module)
		for key, value in pairs(dict) do
			DialogueDictionary[key] = value
		end		
	end
end

return DialogueDictionary
