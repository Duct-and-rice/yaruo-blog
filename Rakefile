
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
        sh "git commit -m '#{message}'"
        sh "git push --force https://duct-and-rice:#{ENV['GH_TOKEN']}@github.com/duct-and-rice/yaruo-blog >/dev/null 2>&1"
    end
    cd "cache" do
        sh "git add ."
        message = "deploy at #{Time.now}"
        sh "git commit -m '#{message}'"
        sh "git push --force https://duct-and-rice:#{ENV['GH_TOKEN']}@github.com/duct-and-rice/yaruo-blog >/dev/null 2>&1"
    end
end
