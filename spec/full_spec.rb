describe "Full Database Test" do
  include_context "db"

  it "stats" do
    db.number_of_cards.should eq(17421)
    db.number_of_printings.should eq(33851)
  end

  it "formats" do
    assert_search_equal "f:standard", "legal:standard"
    assert_search_results "f:extended" # Does not exist according to mtgjson
    assert_search_equal "f:standard",
      %Q[(e:bfz or e:ogw or e:soi or e:w16 or e:emn or e:kld or e:aer or e:akh or e:hou) -"Emrakul, the Promised End" -"Reflector Mage" -"Smuggler's Copter" -"Felidar Guardian" -"Aetherworks Marvel"]
    assert_search_equal 'f:"ravnica block"', "e:rav or e:gp or e:di"
    assert_search_equal 'f:"ravnica block"', 'legal:"ravnica block"'
    assert_search_equal 'f:"ravnica block"', 'b:ravnica'
    assert_search_differ 'f:"mirrodin block" t:land', 'b:"mirrodin" t:land'
  end

  it "block_codes" do
    assert_search_equal "b:rtr", 'b:"Return to Ravnica"'
    assert_search_equal "b:in", 'b:Invasion'
    assert_search_equal "b:som", 'b:"Scars of Mirrodin"'
    assert_search_equal "b:som", 'b:scars'
    assert_search_equal "b:mi", 'b:Mirrodin'
  end

  it "block_special_characters" do
    assert_search_equal %Q[b:us], "b:urza"
    assert_search_equal %Q[b:"Urza's"], "b:urza"
  end

  it "block_contents" do
    assert_search_equal "e:rtr OR e:gtc OR e:dgm", "b:rtr"
    assert_search_equal "e:in or e:ps or e:ap", 'b:Invasion'
    assert_search_equal "e:isd or e:dka or e:avr", "b:Innistrad"
    assert_search_equal "e:lw or e:mt or e:shm or e:eve", "b:lorwyn"
    assert_search_equal "e:som or e:mbs or e:nph", "b:som"
    assert_search_equal "e:mi or e:ds or e:5dn", "b:mi"
    assert_search_equal "e:som", 'e:scars'
    assert_search_equal 'f:"lorwyn shadowmoor block"', "b:lorwyn"
  end

  it "edition_special_characters" do
    assert_search_equal "e:us", %Q[e:"Urza's Saga"]
    assert_search_equal "e:us", %Q[e:"Urza’s Saga"]
    assert_search_equal "e:us or e:ul or e:ud", %Q[e:"urza's"]
    assert_search_equal "e:us or e:ul or e:ud", %Q[e:"urza’s"]
    assert_search_equal "e:us or e:ul or e:ud", %Q[e:"urza"]
  end

  it "part" do
    assert_search_results "part:cmc=1 part:cmc=2",
      "Death", "Life",
      "Tear", "Wear",
      "What", "When", "Where", "Who", "Why",
      "Failure", "Comply",
      "Heaven", "Earth",
      "Claim", "Fame",
      "Appeal", "Authority"
    # Semantics of that changed
    assert_search_results "part:cmc=0 part:cmc=3 part:c:b"
  end

  it "color_identity" do
    assert_search_results "ci:wu t:basic",
      "Island",
      "Plains",
      "Snow-Covered Island",
      "Snow-Covered Plains",
      "Wastes"
  end

  it "year" do
    Query.new("year=2013 t:jace").search(db).card_names_and_set_codes.should eq([
      ["Jace, Memory Adept", "m14", "mbp"],
      ["Jace, the Mind Sculptor", "v13"],
    ])
  end

  it "print_date" do
    assert_search_results %Q[print="29 september 2012"],
      "Archon of the Triumvirate",
      "Carnival Hellsteed",
      "Corpsejack Menace",
      "Grove of the Guardian",
      "Hypersonic Dragon"
  end

  it "print" do
    assert_search_equal "t:planeswalker print=m12", "t:planeswalker e:m12"
    assert_search_results "t:jace print=2013", "Jace, Memory Adept", "Jace, the Mind Sculptor"
    assert_search_results "t:jace print=2012", "Jace, Architect of Thought", "Jace, Memory Adept"
    assert_search_results "t:jace firstprint=2012", "Jace, Architect of Thought"

    # This is fairly silly, as it includes prerelease promos etc.
    assert_search_results "e:soi firstprint<soi",
      "Catalog",
      "Compelling Deterrence",
      "Dead Weight",
      "Eerie Interlude",
      "Fiery Temper",
      "Forest",
      "Ghostly Wings",
      "Gloomwidow",
      "Groundskeeper",
      "Island",
      "Lightning Axe",
      "Macabre Waltz",
      "Mad Prophet",
      "Magmatic Chasm",
      "Mindwrack Demon",
      "Mountain",
      "Plains",
      "Pore Over the Pages",
      "Puncturing Light",
      "Reckless Scholar",
      "Swamp",
      "Throttle",
      "Tooth Collector",
      "Topplegeist",
      "Tormenting Voice",
      "Unruly Mob"

    assert_search_results "e:soi lastprint>soi",
      "Forest",
      "Forsaken Sanctuary",
      "Foul Orchard",
      "Highland Lake",
      "Island",
      "Mountain",
      "Plains",
      "Rabid Bite",
      "Reckless Scholar",
      "Sleep Paralysis",
      "Stone Quarry",
      "Swamp",
      "Tormenting Voice",
      "Woodland Stream"
  end

  it "firstprint" do
    assert_search_results "t:planeswalker firstprint=m12", "Chandra, the Firebrand", "Garruk, Primal Hunter", "Jace, Memory Adept"
  end

  it "lastprint" do
    assert_search_results "t:planeswalker lastprint<=roe", "Chandra Ablaze", "Sarkhan the Mad"
    assert_search_results "t:planeswalker lastprint<=2011",
      "Ajani Goldmane", "Ajani Vengeant", "Chandra Ablaze", "Elspeth Tirel",
      "Garruk Relentless", "Garruk, the Veil-Cursed",
      "Nissa Revane", "Sarkhan the Mad", "Sorin Markov", "Tezzeret, Agent of Bolas"
  end

  it "sort_name" do
    assert_search_results_ordered "t:chandra sort:name",
      "Chandra Ablaze",
      "Chandra Nalaar",
      "Chandra, Flamecaller",
      "Chandra, Pyrogenius",
      "Chandra, Pyromaster",
      "Chandra, Roaring Flame",
      "Chandra, Torch of Defiance",
      "Chandra, the Firebrand"
  end

  it "sort_new" do
    assert_search_results_ordered "t:chandra sort:new",
      "Chandra, Pyrogenius",
      "Chandra, Torch of Defiance",
      "Chandra, Flamecaller",
      "Chandra, Roaring Flame",
      "Chandra, Pyromaster",
      "Chandra, the Firebrand",
      "Chandra Nalaar",
      "Chandra Ablaze"
  end

  it "sort_newall" do
    # Jace v Chandra printing of Chandra Nalaar changes order
    assert_search_results_ordered "t:chandra sort:newall",
      "Chandra, Pyromaster",
      "Chandra, Pyrogenius",
      "Chandra, Torch of Defiance",
      "Chandra, Flamecaller",
      "Chandra, Roaring Flame",
      "Chandra Nalaar",
      "Chandra, the Firebrand",
      "Chandra Ablaze"
  end

  it "sort_old" do
    assert_search_results_ordered "t:chandra sort:old",
      "Chandra Nalaar",
      "Chandra Ablaze",
      "Chandra, the Firebrand",
      "Chandra, Pyromaster",
      "Chandra, Roaring Flame",
      "Chandra, Flamecaller",
      "Chandra, Pyrogenius",
      "Chandra, Torch of Defiance"
  end

  it "sort_oldall" do
    assert_search_results_ordered "t:chandra sort:oldall",
      "Chandra Nalaar",
      "Chandra Ablaze",
      "Chandra, the Firebrand",
      "Chandra, Pyromaster",
      "Chandra, Roaring Flame",
      "Chandra, Flamecaller",
      "Chandra, Pyrogenius",
      "Chandra, Torch of Defiance"
  end

  it "sort_cmc" do
    assert_search_results_ordered "t:chandra sort:cmc",
      "Chandra Ablaze",             # 6
      "Chandra, Flamecaller",       # 6
      "Chandra, Pyrogenius",        # 6
      "Chandra Nalaar",             # 5
      "Chandra, Pyromaster",        # 4
      "Chandra, Torch of Defiance", # 4
      "Chandra, the Firebrand",     # 4
      "Chandra, Roaring Flame"      # 3
  end

  it "alt_rebecca_guay" do
    assert_search_results %Q[a:"rebecca guay" alt:(-a:"rebecca guay")],
      "Ancestral Memories",
      "Angelic Page",
      "Angelic Wall",
      "Auramancer",
      "Aven Mindcensor",
      "Bitterblossom",
      "Boomerang",
      "Channel",
      "Coral Merfolk",
      "Dark Banishing",
      "Dark Ritual",
      "Elven Cache",
      "Elvish Lyrist",
      "Elvish Piper",
      "Forest",
      "Island",
      "Mana Breach",
      "Memory Lapse",
      "Mountain",
      "Mulch",
      "Path to Exile",
      "Phantom Monster",
      "Plains",
      "Sea Sprite",
      "Serra Angel",
      "Spellstutter Sprite",
      "Swamp",
      "Taunting Elf",
      "Thoughtleech",
      "Twiddle",
      "Wall of Wood",
      "Wanderlust",
      "Wood Elves"
  end

  it "alt_test_of_time" do
    assert_search_results "year=1993 alt:year=2015",
      "Basalt Monolith",
      "Counterspell",
      "Dark Ritual",
      "Desert Twister",
      "Disenchant",
      "Earthquake",
      "Forest",
      "Island",
      "Jayemdae Tome",
      "Lightning Bolt",
      "Mahamoti Djinn",
      "Mountain",
      "Nightmare",
      "Plains",
      "Sengir Vampire",
      "Serra Angel",
      "Shatter",
      "Shivan Dragon",
      "Sol Ring",
      "Spell Blast",
      "Swamp",
      "Tranquility"
  end

  it "alt_rarity" do
    assert_search_include "r:common alt:r:uncommon", "Doom Blade"
    assert_search_results "r:common alt:r:mythic",
      "Cabal Ritual",
      "Chainer's Edict",
      "Dark Ritual",
      "Desert",
      "Fyndhorn Elves",
      "Hymn to Tourach",
      "Impulse",
      "Kird Ape",
      "Lotus Petal"
  end

  it "pow_special" do
    assert_search_equal "pow=1+*", "pow=*+1"
    assert_search_include "pow=*", "Krovikan Mist"
    assert_search_results "pow=1+*",
      "Gaea's Avenger", "Lost Order of Jarkeld", "Haunting Apparition", "Mwonvuli Ooze", "Allosaurus Rider"
    assert_search_results "pow=2+*",
      "Angry Mob", "Aysen Crusader"
    assert_search_equal "pow>*", "pow>=1+*"
    assert_search_equal "pow>1+*", "pow>=2+*"
    assert_search_equal "pow>1+*", "pow=2+*"
    assert_search_equal "pow=*2", "pow=*²"
    assert_search_results "pow=*2",
      "S.N.O.T."
  end

  it "tou_special" do
    # Mostly same as power except 7-*
    assert_search_results "tou=7-*", "Shapeshifter"
    assert_search_results "tou>8-*"
    assert_search_results "tou>2-*", "Shapeshifter"
    assert_search_results "tou>8-*"
    assert_search_results "tou<=8-*", "Shapeshifter"
    assert_search_results "tou<=2-*"
  end

  it "is_promo" do
    # mtgjson has different idea what's promo,
    # mci returns 1058 cards
    # scryfall returns 1044
    # It might be a good idea to sort out edge cases
    assert_count_results "is:promo", 1020
  end

  it "is_funny" do
    assert_search_results "abyss is:funny", "Zzzyxas's Abyss"
    assert_search_results "abyss not:funny",
      "Abyssal Gatekeeper",
      "Abyssal Horror",
      "Abyssal Hunter",
      "Abyssal Nightstalker",
      "Abyssal Nocturnus",
      "Abyssal Persecutor",
      "Abyssal Specter",
      "Magus of the Abyss",
      "Reaper from the Abyss",
      "The Abyss"
    assert_search_results "snow is:funny", "Snow Mercy"
    assert_search_results "tiger is:funny", "Paper Tiger", "Stocking Tiger"
  end

  it "mana_variables" do
    assert_search_equal "b:ravnica guildmage mana=hh", "b:ravnica guildmage c:m cmc=2"
    assert_search_equal "e:rtr mana=h", "e:rtr c:m cmc=1"
    assert_search_results "mana>mmmmm",
      "B.F.M. (Big Furry Monster)",
      "Khalni Hydra",
      "Primalcrux"
    assert_count_results "e:ktk (charm OR ascendancy) mana=mno", 10
    assert_count_results "e:ktk mana=mno", 15
    assert_search_results "mana=mmnnnoo",
      "Brilliant Ultimatum",
      "Clarion Ultimatum",
      "Cruel Ultimatum",
      "Titanic Ultimatum",
      "Violent Ultimatum"
    assert_search_results "mana=wwmmmnn",
      "Brilliant Ultimatum",
      "Titanic Ultimatum"
    assert_search_equal "mana=mmnnnoo", "mana=nnooomm"
    assert_search_equal "mana>nnnnn", "mana>ooooo"
    assert_search_equal "mana=mno", "mana={m}{n}{o}"
    assert_search_equal "mana=mmn", "mana=mnn"
    assert_search_equal "mana=mmn", "mana>=mnn mana <=mmn"
    assert_count_results "mana>=mh", 15
    assert_search_results "mana=mh",
      "Bant Sureblade",
      "Crystallization",
      "Esper Stormblade",
      "Grixis Grimblade",
      "Jund Hackblade",
      "Naya Hushblade",
      "Sangrite Backlash",
      "Thopter Foundry",
      "Trace of Abundance"
    assert_search_equal "mana=mh", "mana={m}{h}"
    assert_search_equal "mana={w}{m}", "mana={w}{u} OR mana={w}{b} OR mana={w}{r} OR mana={w}{g}"
    assert_search_equal "mana={m}{h}", "mana={w}{h} OR mana={u}{h} OR mana={b}{h} OR mana={r}{h} OR mana={g}{h}"
    # Only {w}{u/b} of these exists, no cards have hybrid and nonhybrid of same color in mana cost yet
    assert_search_equal "mana={m}{w/b}", "mana={w}{w/b} OR mana={u}{w/b} OR mana={b}{w/b} OR mana={r}{w/b} OR mana={g}{w/b}"
  end

  it "stemming" do
    assert_search_equal "vision", "visions"
  end

  it "comma_separated_set_list" do
    assert_search_equal "e:cmd or e:cm1 or e:c13 or e:c14 or e:c15 or e:c16 or e:cma", "e:cmd,cm1,c13,c14,c15,c16,cma"
    assert_search_equal "st:cmd -alt:-st:cmd", "e:cmd,cm1,c13,c14,c15,c16,cma -alt:-e:cmd,cm1,c13,c14,c15,c16,cma"
  end

  it "command_separated_block_list" do
    assert_search_equal "b:isd or b:soi", "b:isd,soi"
  end

  it "legal everywhere" do
    legality_information("Island").should be_legal_everywhere
    legality_information("Giant Spider").should_not be_legal_everywhere
    legality_information("Birthing Pod").should_not be_legal_everywhere
    legality_information("Naya").should_not be_legal_everywhere
    legality_information("Backup Plan").should_not be_legal_everywhere
  end

  it "legal nowhere" do
    legality_information("Island").should_not be_legal_nowhere
    legality_information("Giant Spider").should_not be_legal_nowhere
    legality_information("Birthing Pod").should_not be_legal_nowhere
    legality_information("Naya").should be_legal_nowhere
    legality_information("Backup Plan").should be_legal_nowhere
  end

  it "is commander" do
    assert_search_equal "is:commander", "(is:primary t:legendary t:creature) OR (t:planeswalker e:c14)"
  end

  # Bugfix
  it "cm1/cma set codes" do
    "e:cm1".should have_result_count(18)
    "e:cma".should have_result_count(289)
  end

  it "gtw/wpn/grc set codes" do
    "e:gtw".should have_result_count(20)
    "e:wpn".should have_result_count(43)
    "e:grc".should have_result_count(0)
  end

  def legality_information(name, date=nil)
    db.cards[name.downcase].legality_information(date)
  end
end
