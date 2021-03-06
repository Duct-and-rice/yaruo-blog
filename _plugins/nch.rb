# vim:set ts=4 sw=4
require 'open-uri'
require 'yaml'
require 'faraday'
require 'digest/sha2'
require 'csv'
require 'oga'

module Jekyll
    class Post
        attr_accessor :header, :index, :name, :mail, :metadata, :body
        def initialize(index, name, mail, metadata, body)
            @index=index
            @name=name
            @mail=mail
            @metadata=metadata
            @body=body
        end
        def header
            "#{index.to_s} 名前：#{name}[#{mail}] 投稿日：#{metadata}"
        end
        def to_liquid
            return { 'header'=>@header,'body'=>@body }
        end
    end

    class Thr
        def initialize(url)
            @url=url
            @digest=Digest::MD5.hexdigest(@url)
            @path="cache/#{@digest}.csv"
            @@dat_cache||={}
            @@html_cache||={}
        end

        def fetch
            url=@url.strip.gsub('/$','')
            part = url.match(/(https?:\/\/.+)\/(?:test|bbs)\/(read(?:_archive)?\.cgi)\/(.+)\/(\d+)\/?/).to_a
            host = part[1]
            cgi = part[2]
            board = part[3]
            thr = part[4]

            mode=nil
            is_euc=false
            if host.include? 'jbbs.shitaraba.net'
                is_euc=true
                if cgi == 'read.cgi'
                    dat_url = "#{host}/bbs/rawmode.cgi/#{board}/#{thr}"
                    mode = 'shitaraba'
                else
                    mode = 'log'
                end
            else
                dat_url = "#{host}/#{board}/dat/#{thr}.dat"
                mode = '2ch'
            end

            body=nil
            if mode != 'log'
                @@dat_cache[dat_url] ||= get_dat(dat_url, is_euc)
                body = @@dat_cache[dat_url]
            end

            if !body
                @@html_cache[dat_url] ||= get_html(url)
                posts = @@html_cache[dat_url]
            else
                if mode == 'shitaraba'
                    posts=body.each_line.map { |line|
                        line.chomp!
                        i, name, mail, metadata, body = line.split('<>')
                        Post.new(i, name.gsub(/<\/?b> ?/, '') ,mail,metadata,body)
                    }
                else
                    i=0
                    posts=body.each_line.map { |line|
                        line.chomp!
                        name, mail, metadata, body = line.split('<>')
                        i+=1
                        Post.new(i, name,mail,metadata,body)
                    }
                end
            end
            posts
        end

        def get_dat(dat_url, is_euc)
            header = {"User-Agent" => "Monazilla/1.00"}
            begin
                puts "  DAT Downloading:" + dat_url
                body = open(dat_url, is_euc ? 'r:eucjp' : 'r:cp932', header) {|w|
                    if w.status.include?"200"
                        body=w.read
                        body=body.encode(Encoding::UTF_8,
                                         :invalid => :replace,
                                         :undef => :replace,
                                         :replace => '')
                        body
                    else
                        p w.status
                        nil
                    end
                }
                body
            rescue OpenURI::HTTPError => e
                raise DownloadError.new(e.message)
            rescue SystemCallError => e
                raise SystemCallError.new(e.message)
            rescue IOError => e
                raise IOError.new(e.message)
            end
        end

        def get_html(url)
            puts "  HTML Downloading:" + url
            html = open(url, 'r:eucjp') {|f|
                body=f.read
                body=body.encode(Encoding::UTF_8)
                body
            }
            if url.include? 'jbbs.shitaraba.net'
                doc = Oga.parse_html(html)

                i = 0
                posts = []
                doc.xpath('//body/dl/*').each {|e|
                    posts[i] ||= []
                    if e.name=='dt'
                        posts[i][0] = e.text
                        if e.xpath('a[position()=2]').attribute('href').length>0
                            posts[i][1] = e.xpath('a[position()=2]').attribute('href')[0].value.match(/mailto:(.+)/)[1]
                        else
                            posts[i][1] = ''
                        end
                    else
                        posts[i][2] = e.to_xml.gsub(/[\r\n]/,'').match(/<dd>(.+)<\/dd>/)[1].gsub(/<\/?(?!br).+?>/,'')
                        i+=1
                    end
                }
                posts=posts.map {|res|
                    m = res[0].match(/(\d+) ：(.+)：(.+)/)
                    i = m[1]
                    name = m[2]
                    metadata = m[3]
                    mail = res[1]
                    body = res[2]
                    Post.new(i, name,mail,metadata,body)
                }
                posts
            end
        end

        def load_from_cache
            begin
                if File.exist?(@path) then
                    data = CSV.read(@path, col_sep:"\t", headers:true)
                    data=data.map {|res|
                        Post.new(res[0].to_i, res[1], res[2], res[3], res[4])
                    }
                    data
                else
                    nil
                end
            rescue IOError => e
                raise IOError.new(e.message)
            end
        end

        def save_cache(posts)
            CSV.open(@path,'wb', col_sep:"\t") {|csv|
                csv << ['id','name','mail','metadata','body']
                i=0
                posts.each {|res|
                    i+=1
                    csv << [res.index.to_s, res.name, res.mail, res.metadata, res.body]
                }
            }
            posts
        end

        def posts
            @posts ||= load_posts
        end

        def load_posts
            cache = load_from_cache 
            if cache.nil? # && !ENV['JEKYLL_DEV'].nil?
                @posts = save_cache(fetch)
            else
                @posts = cache
            end
            return @posts
        end

        def to_liquid
            return { 'body' => self.posts }
        end
    end

    class NchPage < Page
        def initialize(site, base, t_url, range, title, id, episode_num)
            @site = site
            @base = base
            @url = "#{id}-#{episode_num}"
            @range = range
            @title = title
            @tags = ['yaruo-thread', id].join(' ')
            @name = 'index.html'
            @@thread_memo[@url] ||= Thr.new(@url)

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'nch.html')
            self.data['reses']=@@thread_memo[dat_url]
            self.data['title']=title
        end
    end

    class YaruoConverter < Converter
        safe true
        @@thread_memo={}

        def matches(ext)
            ext =~ /^\.yaruo$/i
        end

        def output_ext(ext)
            ".html"
        end

        def convert(content)
            yml=YAML.load(content)
            url = yml['url']
            range = yml['range']
            range = (range['min']-1)..(range['max']-1)
            rms = yml['rm']
            replaces = yml['replace']
            inserts = yml['insert']
            all_posts = Thr.new(url)
            all_posts.load_posts
            if all_posts.posts[range].nil?
                all_posts.save_cache(all_posts.fetch)
            end
            if !replaces.nil?
            for replace in replaces
                if all_posts.posts[replace['target']]
                    all_posts.save_cache(all_posts.posts)
                end
            end
            end
            if all_posts.posts[range].nil?
                p all_posts.posts.size,range, url,Digest::MD5.hexdigest(url)
            end
            posts = all_posts.posts[range]

            tmp=''
            posts.each_with_index do |res,i|
                if !rms.nil? and rms.include?(res.index)
                elsif !replaces.nil? and replaces.any?{|replace| replace['target']==res.index}
                    nres = all_posts.posts[replaces.find_all {|replace| replace['target'] == res.index} [0]['replacement']-1]
                    tmp << %Q{<dl class="res">\n}
                    tmp << %Q{<dt class="res-header">\n}
                    tmp << nres.header
                    tmp << %Q{</dt>\n}
                    tmp << %Q{<dd class="res-body aa">\n}
                    tmp << nres.body.gsub(/http/, '<span>http<span>').gsub(/ftp/, '<span>ftp<span>').gsub(/ttps?:\/\/[\w\/:%#\$&\?\(\)~\.=\+\-]+/,'<a href="h\&">\&</a>')
                    tmp << %Q{</dd>\n}
                    tmp << %Q{</dl>\n}
                    tmp << %Q{</dr>\n\n}
                    tmp << "<!--more-->\n" if i == 0
                else
                    if !inserts.nil?
                        p inserts
                        ins = inserts.select {|insert| return insert['pos']==res.index}
                        for s in ins
                            r = posts[s['target']-range.start]
                            tmp << %Q{<dl class="res">\n}
                            tmp << %Q{<dt class="res-header">\n}
                            tmp << r.header
                            tmp << %Q{</dt>\n}
                            tmp << %Q{<dd class="res-body aa">\n}
                            tmp << r.body.gsub(/http/, '<span>http<span>').gsub(/ftp/, '<span>ftp<span>').gsub(/ttps?:\/\/[\w\/:%#\$&\?\(\)~\.=\+\-]+/,'<a href="h\&">\&</a>')
                            tmp << %Q{</dd>\n}
                            tmp << %Q{</dl>\n}
                            tmp << %Q{</dr>\n\n}
                            tmp << "<!--more-->\n" if i == 0
                        end
                    end
                    tmp << %Q{<dl class="res">\n}
                    tmp << %Q{<dt class="res-header">\n}
                    tmp << res.header
                    tmp << %Q{</dt>\n}
                    tmp << %Q{<dd class="res-body aa">\n}
                    tmp << res.body.gsub(/http/, '<span>http<span>').gsub(/ftp/, '<span>ftp<span>').gsub(/ttps?:\/\/[\w\/:%#\$&\?\(\)~\.=\+\-]+/,'<a href="h\&">\&</a>')
                    tmp << %Q{</dd>\n}
                    tmp << %Q{</dl>\n}
                    tmp << %Q{</dr>\n\n}
                    tmp << "<!--more-->\n" if i == 0
                end
            end
            tmp
        end
    end
end
