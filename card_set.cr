# A set of Quiddler cards
class CardSet < Hash(String, UInt8)
  # Create all possible CardSets that can represent a word. Returns multiple
  # CardSets if the word includes any two-letter cards. For example:
  #   CardSet.from_word("there") # => [
  #     {"th"=>1, "er"=>1, "e"=>1},
  #     {"th"=>1, "e"=>2, "r"=>1},
  #     {"t"=>1, "h"=>1, "er"=>1, "e"=>1},
  #     {"t"=>1, "h"=>1, "e"=>2, "r"=>1}
  #   ]
  def self.from_word(word : String) : Array(self)
    start_set = [new]

    end_sets = from_word(word, start_set)
    end_sets.uniq
  end

  private def self.from_word(word : String, prefix_sets : Array(self)) : Array(self)
    return prefix_sets if word.empty?

    if word.starts_with?(/cl|er|in|th|qu/)
      double_letter_sets = prefix_sets.clone
      double_letter_sets.each { |s| s.add(word[0, 2]) }

      prefix_sets.each { |s| s.add(word[0, 1]) }

      from_word(word[2..], double_letter_sets) + from_word(word[1..], prefix_sets)
    else
      prefix_sets.each { |s| s.add(word[0, 1]) }
      from_word(word[1..], prefix_sets)
    end
  end

  def self.from_cards(cards : Array(String))
    cards.reduce(self.new) { |set, card| set.add card }
  end

  def card_size : UInt32
    sum = 0u32
    each_value { |v| sum += v }
    sum
  end

  def add(card : String) : self
    if self[card]?
      self[card] += 1
    else
      self[card] = 1
    end

    self
  end

  def remove(card_set : self) : self
    card_set.each do |other_card, other_count|
      if self[other_card] < other_count
        raise "can't remove #{other_count} #{other_card} from #{self}"
      end

      self[other_card] -= other_count

      if self[other_card] == 0
        delete(other_card)
      end
    end

    self
  end

  # Override clone so it returns the right type
  def clone : self
    clone = self.class.new
    clone.initialize_clone(self)
    clone
  end

  def includes?(other : CardSet) : Bool
    other.each do |other_card, other_count|
      self_count = self[other_card]?

      if self_count && self_count >= other_count
        next
      else
        return false
      end
    end

    true
  end
end
