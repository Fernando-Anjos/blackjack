require "tty-prompt"

class Game

  VALUES = {
    ace: 11,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
    jack: 10,
    queen: 10,
    king: 10
  }

  def initialize(prompt)
    @prompt = prompt

    @player_money = 100
    @croupier_money = 100
    @current_bet = 10

    @player_hand = []
    @croupier_hand = []

    @deck = build_deck.shuffle
  end

  require "io/console"

  def print_centered_art(art)
    width = IO.console.winsize[1] rescue 80

    art.each_line do |line|
      line = line.rstrip
      padding = [(width - line.length) / 2, 0].max
      puts " " * padding + line
    end
  end

  ART = <<~ASCII
                /$$     /$$                                      /$$           /$$
                |  $$   /$$/                                     |__/          | $$
                \\  $$ /$$//$$$$$$  /$$   /$$       /$$  /$$  /$$ /$$ /$$$$$$$ | $$
                  \\  $$$$//$$__  $$| $$  | $$      | $$ | $$ | $$| $$| $$__  $$| $$
                  \\  $$/| $$  \\ $$| $$  | $$      | $$ | $$ | $$| $$| $$  \\ $$|__/
                | $$ | $$  | $$| $$  | $$      | $$ | $$ | $$| $$| $$  | $$    
                    | $$ |  $$$$$$/|  $$$$$$/      |  $$$$$/$$$$/| $$| $$  | $$ /$$
                    |__/  \\______/  \\______/        \\_____/\\___/ |__/|__/  |__/|__/
  ASCII


  def build_deck
    deck = []

    suits = [:hearts, :diamonds, :clubs, :spades]
    values = [:ace, :two, :three, :four, :five, :six, :seven, :eight, :nine, :ten, :jack, :queen, :king]

    suits.each do |suit|
      values.each do |value|
        deck << { value: value, suit: suit }
      end
    end

    deck
  end
  
  def reset_deck
    @deck = build_deck.shuffle
  end

  def clear_screen
    system("clear") || system("cls")
  end

  def format_card(card)
    "#{card[:value]} of #{card[:suit]}"
  end

  def start
    loop do
      clear_screen
      play_round

      break if game_over?

      answer = @prompt.select("Play again?") do |m|
        m.choice "yes"
        m.choice "no"
      end

      break if answer == "no"
    end
  end

  def reset_hands
    @player_hand = []
    @croupier_hand = []
    @current_bet = 10

    @hidden_card = draw_card
    @visible_card = draw_card

    @croupier_hand << @hidden_card
    @croupier_hand << @visible_card
  end

  def hand_value(hand)
    total = 0
    aces = 0

    hand.each do |card|
      value = card[:value]

      if value == :ace
        total += 11
        aces += 1
      else
        total += VALUES[value]
      end
    end

    while total > 21 && aces > 0
      total -= 10
      aces -= 1
    end

    total
  end

  def draw_card   
    @deck.pop
  end

  def croupier_reveal
    puts "Croupier shows:  #{format_card(@visible_card)}"
  end

  def double_down
    # só permite se tiver dinheiro suficiente
    return puts "Not enough money" if @player_money < @current_bet

    @current_bet *= 2

    card = draw_card
    @player_hand << card

    puts "You drew #{card}"
    puts "Total: #{hand_value(@player_hand)}"
  end

  def player_turn
  2.times { @player_hand << draw_card }

  puts "Your cards: #{@player_hand.map { |c| format_card(c) }.join(", ")}"
  puts "Total: #{hand_value(@player_hand)}"

  loop do
    action = @prompt.select("Hit, stand or double?") do |m|
      m.choice "hit"
      m.choice "stand"
      m.choice "double"
    end

    case action
    when "stand"
      break

    when "double"
      double_down
      return :stand

    when "hit"
      @player_hand << draw_card

      total = hand_value(@player_hand)

      puts "You drew #{format_card(@player_hand.last)}"

      sleep(0.5)

      puts "Your cards: #{@player_hand.map { |c| format_card(c) }.join(", ")}"
      puts "Total: #{total}"

      if hand_value(@player_hand) == 21
        puts "Blackjack! Turn ends."
        return :stand
      end

      if total > 21
        puts "You bust!"
        return :croupier
      end
    end
  end

    :continue
  end

  def croupier_turn
    puts "Revealing card..."
    sleep(1)

    puts "Croupier hand: #{@croupier_hand.map { |c| format_card(c) }.join(", ")}"

    while hand_value(@croupier_hand) < 17
      sleep(1)
      @croupier_hand << draw_card
      puts "Croupier is drawing"
      3.times do
        print "."
        sleep(0.5)
      end
      puts "\nCroupier drew #{format_card(@croupier_hand.last)}" 
    end

    sleep(1)

    puts "Croupier Final hand: #{@croupier_hand.map { |c| format_card(c) }.join(", ")}"

    puts "Croupier stops at #{hand_value(@croupier_hand)}"

    sleep(1)

    resolve_game
  end

  def resolve_game
    player_total = hand_value(@player_hand)
    dealer_total = hand_value(@croupier_hand)

    if dealer_total > 21 || player_total > dealer_total
      print_centered_art(ART)
      @player_money += @current_bet
      @croupier_money -= @current_bet
    elsif player_total < dealer_total
      puts "Dealer wins!"
      @player_money -= @current_bet
      @croupier_money += @current_bet
    else
      puts "Tie!"
    end

    show_money
  end

  def show_money
    puts "Player: #{@player_money} | Dealer: #{@croupier_money}"
  end

  def game_over?
    @player_money <= 0 || @croupier_money <= 0
  end

  def play_round
    reset_deck
    reset_hands
    croupier_reveal    

    result = player_turn
    return if result == :croupier

    croupier_turn
  end

end

prompt = TTY::Prompt.new
game = Game.new(prompt)
game.start







 




