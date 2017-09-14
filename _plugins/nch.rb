require 'open-uri'
require 'yaml'
require 'faraday'
require 'digest/sha2'
require 'csv'
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
        end
        def download_dat
            url=@url.strip.gsub('/$','')
            part = url.match(/(https?:\/\/.+)\/test\/read\.cgi\/(.+)\/(\d+)\/?/).to_a
            dat_url = "#{part[1]}/#{part[2]}/dat/#{part[3]}.dat"
            header = {"User-Agent" => "Monazilla/1.00"}
            begin
                puts "  DAT Downloading"
                body = open(dat_url, 'r:cp932', header,) {|w|
                               body=w.read
                               body=body.encode(Encoding::UTF_8)
                               body
                }
            rescue OpenURI::HTTPError => e
                raise DownloadError.new(e.message)
            rescue SystemCallError => e
                raise SystemCallError.new(e.message)
            rescue IOError => e
                raise IOError.new(e.message)
            end
            i=0
            posts=body.each_line.map { |line|
                line.chomp!
                name, mail, metadata, body = line.split('<>')
                i+=1
                Post.new(i, name,mail,metadata,body)
            }
            posts
        end

        def load_from_cache
            begin
                if File.exist?(@path) then
                    data = CSV.read(@path, col_sep:"\t", headers:true)
                    i=0
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
            load_from_cache || 
                save_cache(download_dat)
            
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
            posts = Thr.new(url)
            posts = posts.posts[range]

            tmp=''
            posts.each_with_index do |res,i|
                tmp << %Q{<dl class="res">\n}
                tmp << %Q{<dt class="res-header">\n}
                tmp << res.header
                tmp << %Q{</dt>\n}
                tmp << %Q{<dd class="res-body aa">\n}
                tmp << res.body
                tmp << %Q{</dd>\n}
                tmp << %Q{</dl>\n}
                tmp << %Q{</dr>\n\n}
                tmp << "<!--more-->\n" if i == 0
            end
            tmp
        end
    end
end
