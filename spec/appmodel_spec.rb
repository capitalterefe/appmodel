require 'spec_helper'
require 'rspec'
require 'json'
require_relative '../lib/appmodel'


describe Appmodel do

  let(:static_file1) { "#{File.dirname(__FILE__)}/fixtures/carmax.app_model.json" }
  let(:appModel) { Appmodel::Model.new(static_file1) }


  before do
    puts '-- before --'
  end

  after do
    puts '-- After --'
  end


  it 'should itemize based on condition visible_when - with action hover' do

    _pg = appModel.getPageElement('page(home).get(cars4sale)')

    triggers=appModel.itemize('visible_when', 'hover', 'page(home).get(cars4sale)')

    puts __FILE__ + (__LINE__).to_s + " triggers => #{triggers}"
#    expect(triggers).to be_a_kind_of(Array)
    expect(triggers).to match_array(["page(home).get(hoverhit00)"])
  end


  it 'should itemize based on condition visible_when - with action title' do

    triggers=appModel.itemize('visible_when', 'title', 'Car[mM]ax.*online')

    puts __FILE__ + (__LINE__).to_s + " triggers => #{triggers}"
#    expect(triggers).to be_a_kind_of(Array)
    expect(triggers).to match_array(["page(home).get(register)"])
  end

  it 'should itemize based on condition click' do


    triggers=appModel.itemize("visible_when", 'click', 'page(research).get(fuel_economy)')
    puts __FILE__ + (__LINE__).to_s + " triggers => #{triggers}"
    expect(triggers).to match_array(["page(home).get(logoff)"])
  end




  it 'should itemize with multiple results' do
    triggers = appModel.itemize('visible_when', 'hover', 'page(home).get(elvis)')

    puts __FILE__ + (__LINE__).to_s + " triggers => #{triggers}"

    expect(triggers).to be_nil
  end

  it 'should iterate over page object' do
    _pg = appModel.getPageElement('page(home).get(cars4sale)')
    appModel.iterate(_pg)
  end

  it 'should iterate over page object given page string' do
    _pg = 'page(home).get(cars4sale)'
    results=appModel.iterate(_pg, _pg)
    i=0
    puts "******** DUMP #{_pg} ************"
    results.each do |arr|
      if arr.is_a?(Array)

        arr.each do |a|
          puts "#{i}. #{a}"
          i+=1
        end

      end

    end

    puts "size: #{results[0].count}"
  end

  it 'should iterate over page object given page string' do
    _pg = 'page(level_1).get(sublevel_1_1).get(sublevel_1_1_1).get(login_frame)'
    results=appModel.flattenPageObject(_pg, "page(level_1).get(sublevel_1_1).get(sublevel_1_1_1).get(login_frame)")

    expect(results.length==7).to be true

    i=0
    puts "******** DUMP #{_pg} ************"
    results.each do |a|
      puts "#{i}. #{a}"
      i+=1
    end

    puts "size: #{results.count}"
  end

end
