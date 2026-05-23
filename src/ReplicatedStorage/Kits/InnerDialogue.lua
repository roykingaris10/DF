local InnerDialogue = {}

InnerDialogue.Lines = {
	Adventure = "What a distant dream… yet the waves already call my name.",
	Stand     = "A lonely dream… but some heights can only be reached alone.",
	Friend    = "An impossible dream… yet my hands still reach for it.",
	Riches    = "A greedy dream… perhaps this hunger was always within me.",
	Fruit     = "A forgotten dream… yet something deep inside tells me it exists.",
}

function InnerDialogue:Get(dreamTrait)
	if not dreamTrait then return nil end
	return self.Lines[dreamTrait]
end

return InnerDialogue
