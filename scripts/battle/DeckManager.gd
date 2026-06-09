class_name DeckManager
extends RefCounted

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var exhaust_pile: Array[CardData] = []
var max_hand_size := 10


func setup(starting_cards: Array[CardData]) -> void:
	draw_pile = starting_cards.duplicate()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	draw_pile.shuffle()


func draw_cards(amount: int) -> int:
	var drawn := 0
	for _index in range(max(0, amount)):
		if hand.size() >= max_hand_size:
			return drawn
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return drawn
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())
		drawn += 1
	return drawn


func move_played_card(card: CardData, exhaust: bool) -> void:
	var index := hand.find(card)
	if index >= 0:
		hand.remove_at(index)
	if exhaust:
		exhaust_pile.append(card)
	else:
		discard_pile.append(card)


func discard_hand() -> int:
	var count := hand.size()
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	return count


func discard_from_hand(amount: int, except_card: CardData = null) -> int:
	var discarded := 0
	for index in range(hand.size() - 1, -1, -1):
		if discarded >= amount:
			break
		var card := hand[index]
		if card == except_card:
			continue
		hand.remove_at(index)
		discard_pile.append(card)
		discarded += 1
	return discarded


func hand_has_type(card_type: String) -> bool:
	for card in hand:
		if card.type == card_type:
			return true
	return false


func is_hand_empty() -> bool:
	return hand.is_empty()
