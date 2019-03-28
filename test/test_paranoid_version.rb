require 'minitest/autorun'
require 'paranoid_versioning'

class TestParanoidVersioning < Minitest::Test

  def setup
    @v = ParanoidVersioning.new(
      :major => '1',
      :minor => '0',
      :patch => '1',
      :milestone => '1',
      :build => '88',
      :branch => "desarrollo",
      :committer => 'pollito_dev',
      :build_date => Date.civil(2019, 03, 05)
    )
    @v_simple = ParanoidVersioning.new(
      :major => '1',
      :minor => '0'
    )
  end

  def test_file_load_complete
    v = ParanoidVersioning.load 'test/version.yml'
    assert @v != v, 'Expected not equal'
  end

  def test_file_load_simple
    v = ParanoidVersioning.load 'test/version.yml'
    assert @v_simple.to_s == v.to_s, "Expected are equal #{v} == #{@v_simple}"
  end

end