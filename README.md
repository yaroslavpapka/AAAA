Phoenix LiveView Platform

Overview

This platform is built using Elixir and Phoenix LiveView, offering a variety of features, including:

A cryptocurrency trading interface with futures functionality (integrating Binance API).

A Blackjack game and sports betting options.

A cryptocurrency wallet manager integrated with MetaMask.

An admin panel with role-based access control.

A blog system with user-generated content.

Authentication via Google OAuth and two-factor authentication (2FA) using Google Authenticator.

Getting Started

To start your Phoenix server:

Install and set up dependencies:

mix setup

Start the Phoenix endpoint:

mix phx.server

or inside IEx:

iex -S mix phx.server

Open localhost:4000 in your browser.

For production deployment, refer to the Phoenix deployment guide.

Modules & Features

Cryptocurrency Trading Platform

Integrates Binance API to fetch real-time market data.

Supports futures trading.

Displays live candlestick charts with price movements.

Allows users to track price history and set alerts.

Casino & Betting System

Blackjack Game:

Built with Phoenix LiveView for real-time gameplay.

Users can place bets, draw cards, and track their balance.

Roulette Game:

Chip-based betting with visual feedback.

Interactive table with different betting options (red/black, odd/even, specific numbers, etc.).

Sports Betting:

Users can place bets on various sports events.

Live odds updates.

MetaWallet - Cryptocurrency Wallet Manager

Demo application for interacting with Ethereum wallets.

Integrates MetaMask for deposits and balance checks.

Uses Ganache to create test ETH accounts for secure transaction testing.

Admin Panel

Role-based access control:

Superadmins: Full control over users, operators, and settings.

Admins: Manage users within their assigned operator scope.

Operators: Handle user requests and transactions.

Logs user activities and system events.

Manages cryptocurrency trading settings and betting limits.

Blog System

Users can create, edit, and manage posts.

Tagging system for better content organization.

Preloads associated tags for efficient queries.

Filters posts by user and supports pagination.

Authentication & Security

Google OAuth2 authentication for easy login.

Two-Factor Authentication (2FA) using Google Authenticator.

Access control: Permissions are enforced based on user roles.

Session management: Secure login/logout handling.

Learn More

Official website: Phoenix Framework

Guides: Phoenix Docs

Forum: Elixir Forum - Phoenix

Source code: GitHub - Phoenix Framework

This platform is a fully featured system combining trading, gaming, and content management in a seamless real-time environment using Phoenix LiveView.

