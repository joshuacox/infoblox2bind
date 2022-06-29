#!/usr/bin/env bats

@test "run it" {
  result="$( ./infoblox2bind.bash ./input.csv &> /dev/null ; echo $? )"
  [ "$result" = '0' ]
}

@test "dig locally" {
  result="$(dig @0 ww2.example.com +short)"
  [ "$result" = '10.0.1.21' ]
}
