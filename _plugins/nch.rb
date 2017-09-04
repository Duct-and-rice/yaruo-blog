require 'cgi'
require 'open-uri'
require 'yaml'
require 'faraday'
require 'digest/sha2'
module Jekyll
    class Post
        attr_accessor :header, :body
        def initialize(index, name, mail, metadata, body)
            @header="#{index.to_s} 名前：#{name}[#{mail}] 投稿日：#{metadata}"
            @body=body
        end
        def to_liquid
            return { 'header'=>@header,'body'=>@body }
        end
    end

    class Thr
        def initialize(url)
            @url=url
        end
        def download
            url=@url
            url=url.strip.gsub('/$','')
            digest=Digest::MD5.hexdigest(url)
            path="dats/#{digest}.dat"
            header = {"User-Agent" => "Monazilla/1.00"}
            begin
                if File.exist?(path) then
                    body = File.open(path, mode = "r"){|f|
                        body=f.read 
                        body
                    }
                else
                    body = open(url, 'r:cp932', header){|w|
                        body=w.read
                        body=body.encode(Encoding::UTF_8)
                        File.open(path, mode = "w"){|f|
                            f.puts body
                        }
                        body
                    }
                end
            rescue OpenURI::HTTPError => e
                raise DownloadError.new(e.message)
            rescue SystemCallError => e
                raise SystemCallError.new(e.message)
            rescue IOError => e
                raise IOError.new(e.message)
            end
            body
        end

        def posts
            @posts ||= load_posts
        end

        def load_posts
            body=download

            i=0

            body.each_line.map { |line|
                line.chomp!

                name, mail, metadata, body = line.split('<>')
                i+=1
                Post.new(i, name,mail,metadata,body)
            }
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
            part = t_url.match(/(https?:\/\/.+)\/test\/read\.cgi\/(.+)\/(\d+)\/?/).to_a
            dat_url = "#{part[1]}/#{part[2]}/dat/#{part[3]}.dat"
            @@thread_memo[dat_url] ||= Thr.new(dat_url)

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
            part = url.match(/(https?:\/\/.+)\/test\/read\.cgi\/(.+)\/(\d+)\/?/).to_a
            dat_url = "#{part[1]}/#{part[2]}/dat/#{part[3]}.dat"
            reses = Thr.new(dat_url)
            reses = reses.posts[range[0]-1..range[1]-1]

            tmp=''
            reses.each_with_index do |res,i|
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
