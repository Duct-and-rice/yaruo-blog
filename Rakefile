require 'tty-prompt'

task :deploy do
    if not Dir.exist?("_deploy")
        sh "git clone -b gh-pages https://github.com/duct-and-rice/yaruo-blog _deploy"
        cd "_deploy" do
            sh "git config user.email travis@travis"
            sh "git config user.name duct-and-rice"
        end 
    end
    if not Dir.exist?("cache")
        sh "git clone -b cache https://github.com/duct-and-rice/yaruo-blog cache"
        cd "cache" do
            sh "git config user.email travis@travis"
            sh "git config user.name duct-and-rice"
        end 
    end
    sh "ls -a _deploy | grep -v -E '\.$|\.\.$|\.git' | xargs rm -rf"
    sh "jekyll b"
    sh "cp -r _site/* _deploy/"
    cd "_deploy" do
        sh "git add ."
        message = "deploy at #{Time.now}"
        sh "git commit -m '#{message}' || echo ''"
        sh "git push --force https://duct-and-rice:#{ENV['GH_TOKEN']}@github.com/duct-and-rice/yaruo-blog >/dev/null 2>&1"
    end
    cd "cache" do
        sh "git add ."
        message = "deploy at #{Time.now}"
        sh "git commit -m '#{message}' || echo ''"
        sh "git push --force https://duct-and-rice:#{ENV['GH_TOKEN']}@github.com/duct-and-rice/yaruo-blog >/dev/null 2>&1"
    end
end

task :build_on_netlify do
    if not Dir.exist?("cache")
        sh "git clone -b cache https://github.com/duct-and-rice/yaruo-blog cache"
        cd "cache" do
            sh "git config user.email netlify@netlify"
            sh "git config user.name duct-and-rice"
        end 
    end
    sh "jekyll b"
    cd "cache" do
        sh "git add ."
        message = "deploy at #{Time.now}"
        sh "git commit -m '#{message}' || echo ''"
        sh "git push --force https://duct-and-rice:#{ENV['GH_TOKEN']}@github.com/duct-and-rice/yaruo-blog >/dev/null 2>&1"
    end
end

task :new_thread do
    prompt = TTY::Prompt.new
    if ENV['url'].nil? then
        url = prompt.ask("URL?:", required: true) {|q| 
            q.validate (/(https?:\/\/.+)\/(?:test|bbs)\/(read(?:_archive)?\.cgi)\/(.+)\/(\d+)\/?/)
        }
    else 
        url = ENV['url']
    end
    if ENV['max'].nil? and ENV['min'].nil? then
        range = prompt.ask("Range?:", convert: :range, required: true) {|q| q.in('1-10000')}
        min = range.min
        max = range.max
    else
        max = ENV['max'].to_i 
        min = ENV['min'].to_i
    end
    if ENV['title'].nil? then
        title = prompt.ask("Title?:", required: true)
    else
        title=ENV['title']
    end
    if ENV['id'].nil? then
        id = prompt.ask("ID?:", required: true)
    else
        id = ENV['id']
    end
    categories_list = %w(yaruo-thread internet-casefile short short-others short-foods)
    categories = prompt.multi_select("Category?:", categories_list)
    body = <<EOS
---
layout: post
title:  "#{title}"
date:   #{Time.now}
categories: #{categories.join(' ')}
---

url: #{url}
range: {min: #{min}, max: #{max}}
EOS
    open("_posts/#{Time.now.strftime("%Y-%m-%d")}-#{id}.yaruo", "w") {|y|
        y.puts(body)
    }
end
