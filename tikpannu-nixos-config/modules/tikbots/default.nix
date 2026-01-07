{
  inputs,
  ...
}:
{
  imports = [
    inputs.tikbots.nixosModules.tikbots
    ./summer-body-bot.nix
    ./wappupokemonbot.nix
    ./tikbot.nix
  ];
}
