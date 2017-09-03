
task :deploy do
    if not Dir.exist?("_deploy")
        sh "git clone -b gh-pages https://github.com/duct-and-rice/yaruo-blog _deploy"
    end
    sh "ls -a _deploy | grep -v -E '\.$|\.\.$|\.git' | xargs rm -rf"
    sh "jekyll b"
    sh "cp -r _site/* _deploy/"
    cd "_deploy" do
        sh "git add ."
        message = "deploy at #{Time.now}"
        sh "git commit -m #{message}"
        sh "git push"
    end
end
