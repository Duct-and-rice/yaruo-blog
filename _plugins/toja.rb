module Jekyll
    module ToJaFilter
        def toja(input)
            patterns = @context.registers[:site].data['toja']
            pattern = patterns.find{|p| p['en']==input}
            if pattern != nil
                pattern['ja']
            else
                input
            end

        end
    end
    Liquid::Template.register_filter(ToJaFilter)
end

