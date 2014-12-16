require 'fastimage'

module MetaInspector
  module Parsers
    class ImagesParser < Base
      delegate [:parsed, :meta, :base_url]         => :@main_parser
      delegate [:each, :length, :size, :[], :last] => :images_collection

      include Enumerable

      def images
        self
      end

      # Returns the parsed image from Facebook's open graph property tags
      # Most major websites now define this property and is usually relevant
      # See doc at http://developers.facebook.com/docs/opengraph/
      # If none found, tries with Twitter image
      def best
        microdata_image || meta['og:image'] || meta['twitter:image'] || detect_best_image
      end

      # Return favicon url if exist
      def favicon
        query = '//link[@rel="icon" or contains(@rel, "shortcut")]'
        value = parsed.xpath(query)[0].attributes['href'].value
        @favicon ||= URL.absolutify(value, base_url)
      rescue
        nil
      end

      private

      def detect_best_image
        meaningful_images.first
      end

      def meaningful_images
        @meaningful_images ||= images_collection.reject { |name|
          name =~ blacklist
        }.map { |name|
          [name, FastImage.size(name)]
        }.reject { |(_, (h, w))|
          !h || !w || h / w > 3 || w / h > 3 || h * w < 5000
        }.sort_by { |(_, (h, w))|
          -h * w
        }.map(&:first)
      end

      def microdata_image
        query = '//*[@itemscope]/*[@itemprop="image"]'
        parsed.xpath(query)[0].inner_text
      rescue
        nil
      end

      def images_collection
        @images_collection ||= absolutified_images
      end

      def absolutified_images
        parsed_images.map { |i| URL.absolutify(i, base_url) }
      end

      def parsed_images
        cleanup(parsed.search('//img/@src'))
      end

      def blacklist
        Regexp.union 'banner', 'background', 'empty', 'sprite', 'base64', '.tiff'
      end
    end
  end
end
