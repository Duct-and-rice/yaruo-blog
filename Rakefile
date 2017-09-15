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

task :new_thread do
    prompt = TTY::Prompt.new
    url = prompt.ask("URL?:", required: true) {|q| 
        q.validate /(https?:\/\/.+)\/(?:test|bbs)\/(read(?:_archive)?\.cgi)\/(.+)\/(\d+)\/?/
    }
    range = prompt.ask("Range?:", convert: :range, required: true) {|q| q.in('1-10000')}
    title = prompt.ask("Title?:", required: true)
    id = prompt.ask("ID?:", required: true)
    categories_list = %w(yaruo-thread internet-casefile short)
    categories = prompt.multi_select("Category?:", categories_list)
    min = range.min
    max = range.max
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
