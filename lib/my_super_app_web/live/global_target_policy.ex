defmodule MySuperAppWeb.GlobalPolicy do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view

  def render(assigns) do
    ~F"""
    Know Before You Go

    Before you virtually sit down at a slot machine or throw in your chips for Draw poker at the game table, please take a moment to brush up on these fundamental casino glossary terms. Slot machines, sports betting, and casino tables are gambling terms that professional gamblers must devote themselves to.
    Minimum Deposits

    A minimum deposit refers to the lowest possible deposit that players can make into their online casino accounts to make real money wagers and win money. Most American online casinos, especially our esteemed and reputable sites, usually have a low threshold of $10 to help out those who don't have deep pockets. However, each site varies, so you might want to research how each operates.
    How to Place Bets

    For slot machines at retail casinos, you can insert your credit or debit card directly into the machine to buy tokens. Or, you can convert your paper money into casino tokens at the cashier to get the reels spinning. For the blackjack or roulette table, for both American and European variants, the player bets with casino chips. Depending on the casino, you might buy the casino chips directly from the dealer or croupier at the table game.

    Before playing slots or a table game like Hold 'em Poker, the wise gambler takes a moment to research the minimum and maximum bets before you gamble any amount of money. Sometimes, the betting requirements and your budget aren't compatible. For slot machines, you can look directly at the pay table to find the betting scale. If you're playing in person, some casino employees on the casino floor should be able to tell. Top-tier online casinos, like Caesars Palace Online Casino and bet365, normally have an info section on their games, including the live dealer, to find the different betting requirements.
    Caps on Games

    Even if you fancy yourself a high roller, there's usually a maximum bet or a betting ceiling on any gambling game. Capping bets serves as a guard for the casino to maintain a house edge, but also to prevent having one player hogging the table. In addition to the casino having to potentially shell out an insane amount of money for out-of-whack bets, betting too large may deter others from playing games.
    Withdrawals/Cashing Out

    Cashing out is one of the gambling terms that all gamblers dream of. Making withdrawals means you had a winning hand, a winning streak, or came out ahead with your money wagered. If you're in a retail casino, take your tokens or chips to the cashier. Sometimes, the card game or roulette table requires the dealer or cashier to cash out your winning chips. For those playing online casino games or participating in online sports betting, you can proceed to the cashier. Select your withdrawal method and the amount. Please note that each casino has a minimum and maximum amount of money that all members can withdraw at a given time.
    Online Casino Terms Glossary

    With the gambling basics under your belt, the next stage of this casino glossary is to define most of the common gambling terms you need to understand to play games in the casino world and win.

    Here's a comprehensive list of online casino terms all players should know:
    """
  end
end
