require 'json'

module Appmodel

  class Model
    attr_accessor :_file
    attr_accessor :app_model

    def initialize(f=nil)
      if !f.nil?
        @_file=f
        loadPages(@_file)
      end
    end

    # _a : frame(xyz).frame(123), <locator>
    def self.parseLocator(_locator)
      hit=nil

      if _locator.is_a?(String)

        rc=_locator.match(/^\s*([([fF]rame\([^\(]*?\)\.)]*)\.([lL]ocator\((.*)\))\s*$/)

        if rc
          hit = { 'frame' => rc[1], 'locator' => rc[3] }
        elsif _locator.match(/^\s*[lL]ocator\((.*)\)\s*$/)
          hit = { 'locator' => _locator.match(/^\s*[lL]ocator\((.*)\)\s*$/)[1] }
        else
          rc=_locator.match(/^\s*([([fF]rame\([^\(]*?\)\.)]*)\.([lL]ocator\((.*)\))\s*$/)

          if rc
            hit = { 'frame' => rc[1], 'locator' => rc[2]}
          end
        end

      elsif _locator.is_a?(Hash) && _locator.has_key?('locator')
        hit = { 'locator' => _locator['locator']}
        if _locator.has_key?('frame')
          hit['frame'] = _locator['frame']
        end
      end

      hit

    end


    def self.isPageObject?(_locator)
      rc=false
      if _locator.is_a?(String)
        if _locator.match(/^\s*page\s*\(\s*[\w\d_\-]+\s*\)/i)
          rc=true
        elsif _locator.match(/^\s*frame\(.*\)\.locator\(.*\)\s*$/)
          rc=true
        end

      elsif _locator.is_a?(Hash)
        rc = _locator.has_key?('locator') || _locator.has_key?(:locator)
      end

      rc
    end



    def getAppModel()
      @app_model
    end

    def loadPages(jlist)

      json_list=[]
      if jlist.kind_of?(String)
        json_list << jlist
      else
        json_list=jlist
      end

      jsonData={}
      json_list.each  { |f|
        puts __FILE__ + (__LINE__).to_s + " JSON.parse(#{f})"

        begin
          data_hash = JSON.parse File.read(f)
          jsonData.merge!(data_hash)
        rescue JSON::ParserError
          puts "raise JSON::ParseError - #{f.to_s}"
          raise "JSONLoadError"
        end

      }
      puts "merged jsonData => " + jsonData.to_json
      @app_model = jsonData
    end


    # getPageElement("page(login).get(login_form).get(button)")
    def getPageElement(s)
      puts __FILE__ + (__LINE__).to_s + " getPageElement(#{s})"

      if s.match(/^\s*\//) || s.match(/^\s*css\s*=/i) || s.match(/^\s*#/)
        puts __FILE__ + (__LINE__).to_s + " getPageElement(#{s} return nil"
        return nil
      end

      hit=@app_model

      nodes = s.split(/\./)

      nodes.each { |elt|

        puts __FILE__ + (__LINE__).to_s + " process #{elt}"
        getter = elt.split(/\(/)[0]
        _obj = elt.match(/\((.*)\)/)[1]

        puts __FILE__ + (__LINE__).to_s + " getter : #{getter}  obj: #{_obj}"

        if getter.downcase.match(/(page|pg)/)
          puts __FILE__ + (__LINE__).to_s + " -- process page --"
          hit=@app_model[_obj]
        elsif getter.downcase=='get'

          if !hit.nil? && hit.has_key?(_obj)
            hit=hit[_obj]

            if hit.is_a?(String) && hit.match(/\s*(file)\((.*)\)/)
              puts __FILE__ + (__LINE__).to_s + "  LOAD Sub pageObject: #{hit}"
            end

          else
            puts __FILE__ + (__LINE__).to_s + " Missing getter : #{_obj.to_s}"
            return nil
          end

        else
          puts __FILE__ + (__LINE__).to_s + " getter : #{getter} is unknown."
          return nil
        end
        puts __FILE__ + (__LINE__).to_s + " HIT => #{hit}"
      }

      hit

    end



    # visible_when: hover(page(x).get(y).get(z))
    def itemize(condition='visible_when', _action='hover', _pgObj=nil)
      @results=hits(nil, @app_model, condition, _action, _pgObj)

      puts "[itemize] => #{@results}"

      @results
    end


    def hits(parent, h, condition, _action, pg)
      #  puts __FILE__ + (__LINE__).to_s + " collect_item_attributes(#{h})"
      result = []


      if h.is_a?(Hash)

        h.each do |k, v|
          puts __FILE__ + (__LINE__).to_s + " Key: #{k} => #{v}"
          if k == condition
            #  h[k].each {|k, v| result[k] = v } # <= tweak here
            if !v.is_a?(Array) && v.match(/^\s*#{_action}\s*\((.*)\)\s*$/i)

              pageObject=v.match(/^\s*#{_action}\s*\((.*)\)\s*$/i)[1]

              puts __FILE__ + (__LINE__).to_s + " <pg, pageObject> : <#{pg}, #{pageObject}>"
              #         result[k] = v

              #          puts '*******************'
              #          puts __FILE__ + (__LINE__).to_s + " HIT : #{h[k]}"
              #          result << { h[k] => v }

              if pg.nil?
                result << parent
              elsif pg == pageObject
                result << parent

              end

            elsif v.is_a?(Array)

              v.each do |vh|
                puts " =====> #{vh}"

                if vh.is_a?(Hash) && vh.has_key?(condition) && vh[condition].match(/^\s*#{_action}\s*/i)

                  pageObject=vh[condition].match(/^\s*#{_action}\s*\((.*)\)\s*$/i)[1]


                  puts __FILE__ + (__LINE__).to_s + " matched on #{_action}, pg:#{pg}, #{pageObject}"

                  if pg.nil?
                    result << parent
                  elsif pg == pageObject
                    result << parent
                  end

                end

              end

            end

          elsif v.is_a? Hash
            if parent.nil?
              _rc = hits("page(#{k})", h[k], condition, _action, pg)
            else
              _rc = hits("#{parent}.get(#{k})", h[k], condition, _action, pg)
            end


            if !(_rc.nil? || _rc.empty?)


              result << _rc

              puts __FILE__ + (__LINE__).to_s + " ADDING  #{k} : #{_rc}"
              #           puts "====> #{k} : #{_rc.class} : #{_rc.length}"


              result.flatten!
            end


          end
        end

      end



      result=nil if result.empty?
      puts __FILE__ + (__LINE__).to_s + " result : #{result}"
      result
    end

    def flattenPageObject(h, path="")
      rc=iterate(h, path)
      if rc.is_a?(Array)
        return rc[0]
      end

      nil
    end

    def iterate(h, path="")
      rc=true
      assertions=[]

      puts __FILE__ + (__LINE__).to_s + " ===== iterate(#{h}, #{path}) ====="

      if h.is_a?(String)
        puts __FILE__ + (__LINE__).to_s + " => process #{h}"
        if h.match(/^\s*(page)\s*\(.*\)\s*$/i)
          puts __FILE__ + (__LINE__).to_s + " => process Page #{h}"
          page_elt = getPageElement(h)
          puts __FILE__ + (__LINE__).to_s + " => #{page_elt}"
          assertions << iterate(page_elt, path)
        else
          puts __FILE__ + (__LINE__).to_s + " UNKNOWN: #{h}"
          assertions << "#{h} : unknown"
        end

      elsif h.is_a?(Hash) && h.has_key?('locator')

        puts __FILE__ + (__LINE__).to_s + " == add #{h} =="
        assertions << { :path => path, :data => h }

      elsif h.is_a?(Hash)

        puts __FILE__ + (__LINE__).to_s + "Keys.size: #{h.keys[0]}"

        if h.keys.size==1 && h[h.keys[0]].is_a?(Hash) && h[h.keys[0]].has_key?('locator')

          puts __FILE__ + (__LINE__).to_s + " add assertion #{h}"
          assertions << { :path => path, :data => h }

        elsif h.keys.size==1 && h[h.keys[0]].is_a?(Hash)

          # "id": {
          # }

          _id = h.keys[0]
          puts __FILE__ + (__LINE__).to_s + " LocatorID : #{_id}"

          if true
          h[_id].each_pair { |_k, _h|

            puts __FILE__ + (__LINE__).to_s + " | id(#{_id}) => #{_k}, #{_h}"

            if _h.keys.size==1 && _h[_h.keys[0]].is_a?(Hash) && !_h[_h.keys[0]].has_key?('locator')
              puts __FILE__ + (__LINE__).to_s + " id(#{_id}) => #{_h}"
              _a = iterate(_h, "#{path}.#{_id}")
              _a.each do |_e|
                assertions << _e
              end
            elsif _h.keys.size==1 && _h[_h.keys[0]].is_a?(Hash) && _h[_h.keys[0]].has_key?('locator')
              assertions << { :path => "#{path}.#{_id}", :data => h[_h.keys[0]] }
            elsif _h.is_a?(Hash) && _h.has_key?('locator')
              assertions << { :path => "#{path}.#{_id}.#{_k}", :data => _h }
            else
              puts __FILE__ + (__LINE__).to_s + " | id(#{path}.#{_id}.#{_k}) - #{_h}"

              _h.each do |k, v|
#                puts __FILE__ + (__LINE__).to_s + " processing #{_id}.#{k}, #{v}"
                if v.is_a?(Hash) && v.has_key?('locator')
                  puts __FILE__ + (__LINE__).to_s + " processing #{_id}.#{_k}.#{k}"
                elsif v.is_a?(Hash) || v.is_a?(Array)
                  puts __FILE__ + (__LINE__).to_s + " processing #{_id}.#{k} - #{v}"
                  _a = iterate(v, "#{path}.#{_id}.#{k}")
                  _a.each do |_e|
                    assertions << _e
                  end
                else
                  puts("Assert => k is #{k}, value is #{v}")
             #     assertions << "#{k} #{v}"
                  rc=rc && true
                end
              end

              puts __FILE__ + (__LINE__).to_s + " adding assertions id(#{_id}.#{_k}) - #{_h}"
              assertions << "id(#{_id}.#{_k}) - #{_h}"
            end

          }
          end



        else

          puts __FILE__ + (__LINE__).to_s + " ** process #{h} **"
          _list=Array.new
          h.each do |k, v|
            if v.is_a?(Hash) && v.has_key?('locator')

              puts __FILE__ + (__LINE__).to_s + " add to assertion #{k} => #{v}"
              _list.push({ :path => "#{path}.get(#{k})", :dat => v })

              puts " _list ==> #{_list}"
            elsif v.is_a?(Hash) || v.is_a?(Array)

              # login_form => {"userid"=>{"locator"=>"#userid"}, "password"=>{"locator"=>"#pass"}}


              puts __FILE__ + (__LINE__).to_s + " >>>>  #{k} => #{v} <<<<<"


              _a = iterate(v, "#{path}.get(#{k})")
              _a.each do |_e|
                assertions << _e
              end
            else
              puts(__FILE__ + (__LINE__).to_s + " k is #{k}, value is #{v}")
              assertions << "#{k} #{v}"
            end
          end

         # assertions << _list.flatten
          if !_list.empty?
            _list.each do |_e|
              assertions << _e
            end
          end

        end

      else
        puts __FILE__ + (__LINE__).to_s + " Huh?"
        assertions << nil
      end

      puts __FILE__ + (__LINE__).to_s + " assertions => #{assertions}"
      assertions

    end

  end

end

