require_relative "test_helper"

class CardDatabaseRTRTest < Minitest::Test
  def setup
    @db = CardDatabase.new(Pathname(__dir__) + "index/rtr_block.json")
  end

  def test_boolean
    assert_search_results "(e:rtr or e:dgm) r:mythic c:w",
      "Blood Baron of Vizkopa",
      "Council of the Absolute",
      "Legion's Initiative",
      "Voice of Resurgence",
      "Angel of Serenity",
      "Armada Wurm",
      "Isperia, Supreme Judge",
      "Sphinx's Revelation",
      "Trostani, Selesnya's Voice"

    assert_search_equal "(e:rtr OR e:dgm) t:goblin or t:elf", "((e:rtr OR e:dgm) t:goblin) or t:elf"
    assert_search_differ "(e:rtr OR e:dgm) t:goblin or t:elf", "(e:rtr OR e:dgm) (t:goblin or t:elf)"
    assert_search_equal "t:human t:warrior", "t:human AND t:warrior"
    assert_search_equal "t:human t:warrior", "t:human OR t:warrior"
    assert_search_equal "t:human t:warrior", 't:"human warrior"'
    assert_search_equal "t:human t:warrior", 't:"warrior human"'
  end

  def test_filter_colors_multicolored
    assert_search_include "c:g", "Rubblebelt Raiders"
    assert_search_include "c:r", "Rubblebelt Raiders"
    assert_search_include "c:m", "Rubblebelt Raiders"
    assert_search_include "c:rw", "Rubblebelt Raiders"
    assert_search_include "c:wubrg", "Rubblebelt Raiders"
    assert_search_include "c:wubrgm", "Rubblebelt Raiders"

    assert_search_exclude "c:w", "Rubblebelt Raiders"
    assert_search_exclude "c!g", "Rubblebelt Raiders"
    assert_search_exclude "c!g", "Rubblebelt Raiders"
    assert_search_exclude "c:c", "Rubblebelt Raiders"
    assert_search_exclude "c:l", "Rubblebelt Raiders"
  end

  # It is broken in magiccards.info, fixing so "ci:rg" means "can be played in RG commander deck"
  def test_color_identity
    assert_search_include "ci:rg", "Rubblebelt Raiders"
    assert_search_include "ci:rug", "Rubblebelt Raiders"
    assert_search_exclude "ci:r", "Rubblebelt Raiders"
    assert_search_exclude "ci:c", "Rubblebelt Raiders"

    assert_search_include "ci:rw", "Alive // Well"
    assert_search_include "ci:rgw", "Alive // Well"
    assert_search_include "ci:rw", "Alive // Well"
  end

  def test_edition
    assert_search_equal "e:rtr", "e:ravnica"
    assert_search_equal "e:rtr", "e:return"
    assert_search_equal "e:rtr", 'e:"Return to Ravnica"'
    assert_search_equal "e:gtc", "e:Gatecrash"
    assert_search_equal "e:dgm", %Q[e:"dragon's maze"]
    assert_search_equal "e:dgm", "e:maze"
  end

  def test_block
    assert_search_equal "e:rtr OR e:gtc OR e:dgm", "b:rtr"
    assert_search_equal "e:rtr OR e:gtc OR e:dgm", 'b:"Return to Ravnica"'

    assert_equal "this test is any good", false, "Doesn't really do anything yet, everything is same block"
  end

  def test_is_split
    assert_search_results "Alive // Well", "Alive // Well"
    assert_search_results "!Alive // Well", "Alive // Well"
    assert_search_results "Alive", "Alive // Well"
    assert_search_results "Well", "Alive // Well"

    assert_search_include 'o:fuse o:centaur o:"gain 2 life"', "Alive // Well"

    assert_search_include "is:split", "Rubblebelt Raiders"
    assert_search_exclude "is:split", "Alive // Well"
  end
end
