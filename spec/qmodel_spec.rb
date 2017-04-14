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


  describe 'Verify API isPageObject' do

    it 'should recognize pageObject DSL using page(A).get(B) format' do
      rc = Appmodel::Model.isPageObject?('page(home).get(childElement')
      expect(rc).to be(true)
    end

    it 'should recognize pageObject DSL using frame().locator() format' do
      rc = Appmodel::Model.isPageObject?( 'frame(//xyz).locator(css=#xyz)' )
      expect(rc).to be(true)
    end

    it 'should recognize pageObject DSL using {:locator => x } format' do
      rc = Appmodel::Model.isPageObject?( { :locator => 'xyz'} )
      expect(rc).to be(true)
    end

    it 'should return false with invalid String DSL' do
      rc = Appmodel::Model.isPageObject?( 'xyz')
      expect(rc).to be(false)
    end


    it 'should return false with invalid Hash DSL' do
      rc = Appmodel::Model.isPageObject?( { :xyz => 'abc'})
      expect(rc).to be(false)
    end

  end

  describe 'parseLocator' do

    it 'should parse frame with locator' do
      _hit = Appmodel::Model.parseLocator('frame(f1).locator(css=#id)')
      expect(_hit).to have_key('frame')
    end

    it 'should parse frame with locator regardless of case' do
      _hit = Appmodel::Model.parseLocator('Frame(f1).Locator(css=#id)')
      expect(_hit).to have_key('frame')
    end

    it 'should parse without frame - only locator regardless of case' do
      _hit = Appmodel::Model.parseLocator('Locator(css=#id)')
      expect(_hit).to have_key('locator')
    end

    it 'should parse with Hash' do
      _hit = Appmodel::Model.parseLocator({ 'frame' => 'f1', 'locator' => '//*[@id="test"]' })
      expect(_hit).to have_key('locator')
    end

    it 'should return locator' do
      _hit = Appmodel::Model.parseLocator("//*[@id='main']/div[1]/table[1]/thead/tr/th[text()='Type'][1]")
      puts __FILE__ + (__LINE__).to_s + " HIT => #{_hit}"
    end

  end


  describe 'Verify API getPageElement' do

    it 'should return an existing element' do
      _pg = appModel.getPageElement('page(home).get(cars4sale)')
      expect(_pg).to have_key('locator')
    end

    it 'should not find an existing PO' do
      _pg = appModel.getPageElement('page(xxxhome).get(cars4sale)')
      expect(_pg).to be(nil)
    end

  end

  describe 'Work with Frames' do
    it 'should return an existing element' do
      _pg = appModel.getPageElement('page(sideNav).get(home_link)')
      expect(_pg.has_key?('frame') && _pg.has_key?('locator')).to be(true)
    end
  end

  describe 'toBy API' do

    it 'should conver to XPATH' do
      _rc = Appmodel::Model.toBy('//*[@id="test"]')
      expect(_rc).to have_key(:xpath)
    end

    it 'should return locator' do
      _rc = Appmodel::Model.toBy('//*[@id="test"]')
      expect(_rc[:xpath]).to eql('//*[@id="test"]')
    end

    it 'should conver to CSS' do
      _rc = Appmodel::Model.toBy('css=#test')
      expect(_rc).to have_key(:css)
    end

    it 'should return CSS locator' do
      _rc = Appmodel::Model.toBy('css=#test')
      expect(_rc[:css]).to eql('#test')
    end

    it 'should return Selenium locator with appModel' do
      _rc = Appmodel::Model.toBy('page(sideNav).get(home_link)', appModel)
      expect(_rc[:css]).to eql("#name")
    end
  end


end
