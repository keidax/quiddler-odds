require "csv"

require "./card_set"

card_counts = {} of String => Int32
File.open("data/cards.csv") do |card_file|
  CSV.each_row(card_file) do |row|
    card_counts[row[0].downcase] = row[2].to_i
  end
end

deck = [] of String
card_counts.each do |card, count|
  count.times { deck << card }
end

words = Set(String).new
words.concat(File.read_lines("data/regular_words.txt"))

WORD_SETS = Set(CardSet).new
words.each do |word|
  card_sets = CardSet.from_word(word).reject { |c| c.card_size < 2 }
  WORD_SETS.concat(card_sets)
end

WORD_SETS_BY_SIZE = WORD_SETS.group_by(&.card_size)

INVALID_CACHE = Set(CardSet).new

# Check if the given cards can form one or more valid words, with no cards left
# over.
def playable_hand?(cards : CardSet) : Bool
  return false if cards.card_size < 2
  return false if INVALID_CACHE.includes?(cards)
  return true if WORD_SETS.includes?(cards)

  if cards.card_size < 4
    # We can't split this hand any further
    INVALID_CACHE << cards
    return false
  end

  # Try extracting smaller words from this set of cards, then check if the
  # remaining cards are valid
  max_word_size = cards.card_size//2
  (2..max_word_size).each do |split_size|
    WORD_SETS_BY_SIZE[split_size].each do |smaller_word|
      if cards.includes?(smaller_word)
        sub_cards = cards.clone.remove(smaller_word)
        return true if playable_hand?(sub_cards)
      end
    end
  end

  INVALID_CACHE << cards
  false
end

def playable_with_discard?(cards : Array(String)) : Bool
  hand_size = cards.size - 1

  cards.each_combination(hand_size, reuse: true) do |hand_after_discard|
    if playable_hand?(CardSet.from_cards(hand_after_discard))
      return true
    end
  end

  false
end

def test_turn(deck, hand_size, trials = 10000)
  playable = 0

  trials.times do
    # Includes the dealt hand, the face-up card, and the first drawn card
    available_cards = deck.sample(hand_size + 2)

    hand_with_top_card = available_cards[0..hand_size]
    if playable_with_discard?(hand_with_top_card)
      playable += 1
      next
    end

    hand_with_draw = available_cards[0...hand_size] << available_cards.last
    if playable_with_discard?(hand_with_draw)
      playable += 1
    end
  end

  puts "#{hand_size}: #{playable/trials}"
end

test_turn(deck, 3)
test_turn(deck, 4)
test_turn(deck, 5)
test_turn(deck, 6)
test_turn(deck, 7)
test_turn(deck, 8)
test_turn(deck, 9)
test_turn(deck, 10)
