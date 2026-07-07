require 'rails_helper'
require 'rails/dom/testing/assertions'

RSpec.describe Notifications::Markdown do
  include Notifications::Markdown

  describe "#markdown_to_html" do
    include Rails::Dom::Testing::Assertions

    def markdown_to_html(markup)
      @html_document = Nokogiri::HTML(super(markup))
    end

    def document_root_element
      @html_document.root
    end

    it "expands placeholders with url in to links" do
      markdown_to_html <<~MD
        ((url))
      MD

      assert_select "p" do
        assert_select "a", "{{url}}"
        assert_select "a:match('href', ?)", "{{url}}"
        assert_select "a:match('style', ?)", "word-wrap: break-word;"
        assert_select "a:match('style', ?)", "color: #1D70B8;"
      end
    end

    it "converts Notify placeholders to Handlebars" do
      markdown_to_html <<~MD
        Hello, ((name))!
      MD

      assert_select "p", "Hello, {{name}}!"
    end

    it "formats level 1 headings as <h2> elements" do
      markdown_to_html <<~MD
        # Heading 1
      MD

      assert_select "h2", "Heading 1"
      assert_select "h2:match('style', ?)", "Margin: 0 0 20px 0;"
      assert_select "h2:match('style', ?)", "padding: 0;"
      assert_select "h2:match('style', ?)", "font-size: 27px;"
      assert_select "h2:match('style', ?)", "line-height: 35px;"
      assert_select "h2:match('style', ?)", "font-weight: bold;"
      assert_select "h2:match('style', ?)", "color: #0B0C0C;"
    end

    it "formats other level headings as <p> elements" do
      markdown_to_html <<~MD
        ## Heading 2
      MD

      assert_select "p", "Heading 2"
      assert_select "p:match('style', ?)", "Margin: 0 0 20px 0;"
      assert_select "p:match('style', ?)", "font-size: 19px;"
      assert_select "p:match('style', ?)", "line-height: 25px;"
      assert_select "p:match('style', ?)", "color: #0B0C0C;"
    end

    it "formats horizontal rules" do
      markdown_to_html <<~MD
        ---
      MD

      assert_select "hr"
      assert_select "hr:match('style', ?)", "border: 0;"
      assert_select "hr:match('style', ?)", "height: 1px;"
      assert_select "hr:match('style', ?)", "background: #B1B4B6;"
      assert_select "hr:match('style', ?)", "Margin: 30px 0 30px 0;"
    end

    it "formats paragraphs" do
      markdown_to_html <<~MD
        Hello, World!
      MD

      assert_select "p", "Hello, World!"
      assert_select "p:match('style', ?)", "Margin: 0 0 20px 0;"
      assert_select "p:match('style', ?)", "font-size: 19px;"
      assert_select "p:match('style', ?)", "line-height: 25px;"
      assert_select "p:match('style', ?)", "color: #0B0C0C;"
    end

    it "hard wraps paragraphs" do
      markdown_to_html <<~MD
        Thanks,
        The Public Petitions team
        The Scottish Parliament
      MD

      assert_select "p" do
        assert_select "br", count: 2
      end
    end

    it "formats blockquotes" do
      markdown_to_html <<~MD
        > Hello, World!
      MD

      assert_select "blockquote", "Hello, World!"
      assert_select "blockquote:match('style', ?)", "Margin: 0 0 20px 0;"
      assert_select "blockquote:match('style', ?)", "border-left: 10px solid #B1B4B6;"
      assert_select "blockquote:match('style', ?)", "padding: 15px 0 0.1px 15px;"
      assert_select "blockquote:match('style', ?)", "font-size: 19px;"
      assert_select "blockquote:match('style', ?)", "line-height: 25px;"
    end

    it "formats ordered lists" do
      markdown_to_html <<~MD
        1. Option 1
        2. Option 2
        3. Option 3
      MD

      assert_select "table:match('style', ?)", "padding: 0 0 20px 0;"
      assert_select "table:match('role', ?)", "presentation"
      assert_select "table td:match('style', ?)", "font-family: Helvetica, Arial, sans-serif;"

      assert_select "table ol:match('style', ?)", "Margin: 0 0 0 20px;"
      assert_select "table ol:match('style', ?)", "padding: 0;"
      assert_select "table ol:match('style', ?)", "list-style-type: decimal;"

      assert_select "table li:match('style', ?)", "Margin: 5px 0 5px;"
      assert_select "table li:match('style', ?)", "padding: 0 0 0 5px;"
      assert_select "table li:match('style', ?)", "font-size: 19px;"
      assert_select "table li:match('style', ?)", "line-height: 25px;"
      assert_select "table li:match('style', ?)", "color: #0B0C0C;"

      assert_select "table li", "Option 1"
      assert_select "table li", "Option 2"
      assert_select "table li", "Option 3"
    end

    it "formats unordered lists" do
      markdown_to_html <<~MD
        * Option 1
        * Option 2
        * Option 3
      MD

      assert_select "table:match('style', ?)", "padding: 0 0 20px 0;"
      assert_select "table:match('role', ?)", "presentation"
      assert_select "table td:match('style', ?)", "font-family: Helvetica, Arial, sans-serif;"

      assert_select "table ul:match('style', ?)", "Margin: 0 0 0 20px;"
      assert_select "table ul:match('style', ?)", "padding: 0;"
      assert_select "table ul:match('style', ?)", "list-style-type: disc;"

      assert_select "table li:match('style', ?)", "Margin: 5px 0 5px;"
      assert_select "table li:match('style', ?)", "padding: 0 0 0 5px;"
      assert_select "table li:match('style', ?)", "font-size: 19px;"
      assert_select "table li:match('style', ?)", "line-height: 25px;"
      assert_select "table li:match('style', ?)", "color: #0B0C0C;"

      assert_select "table li", "Option 1"
      assert_select "table li", "Option 2"
      assert_select "table li", "Option 3"
    end

    it "autolinks urls" do
      markdown_to_html <<~MD
        https://petitions.parliament.scot
      MD

      assert_select "p" do
        assert_select "a", "https://petitions.parliament.scot"
        assert_select "a:match('href', ?)", "https://petitions.parliament.scot"
        assert_select "a:match('style', ?)", "word-wrap: break-word;"
        assert_select "a:match('style', ?)", "color: #1D70B8;"
      end
    end

    it "formats links" do
      markdown_to_html <<~MD
        [Scottish Petitions](https://petitions.parliament.scot)
      MD

      assert_select "p" do
        assert_select "a", "Scottish Petitions"
        assert_select "a:match('href', ?)", "https://petitions.parliament.scot"
        assert_select "a:match('style', ?)", "word-wrap: break-word;"
        assert_select "a:match('style', ?)", "color: #1D70B8;"
      end
    end

    it "formats links with titles" do
      markdown_to_html <<~MD
        [See what we are doing](https://petitions.parliament.scot "Scottish Petitions")
      MD

      assert_select "p" do
        assert_select "a", "See what we are doing"
        assert_select "a:match('href', ?)", "https://petitions.parliament.scot"
        assert_select "a:match('style', ?)", "word-wrap: break-word;"
        assert_select "a:match('style', ?)", "color: #1D70B8;"
        assert_select "a:match('title', ?)", "Scottish Petitions"
      end
    end

    it "doesn't format emphasis tags" do
      markdown_to_html <<~MD
        *Hello, World!*
      MD

      assert_select "p", "Hello, World!"
      assert_select "p em", count: 0
    end

    it "doesn't format double emphasis tags" do
      markdown_to_html <<~MD
        **Hello, World!**
      MD

      assert_select "p", "Hello, World!"
      assert_select "p strong", count: 0
    end

    it "doesn't format triple emphasis tags" do
      markdown_to_html <<~MD
        ***Hello, World!***
      MD

      assert_select "p", "Hello, World!"
      assert_select "p strong em", count: 0
    end

    it "doesn't format code tags" do
      markdown_to_html <<~MD
        This is `some code`
      MD

      assert_select "p", "This is some code"
      assert_select "p code", count: 0
    end

    it "doesn't format underline tags" do
      markdown_to_html <<~MD
        _Hello, World!_
      MD

      assert_select "p", "Hello, World!"
      assert_select "p u", count: 0
    end

    it "doesn't format strikethrough tags" do
      markdown_to_html <<~MD
        ~~Hello, World!~~
      MD

      assert_select "p", "Hello, World!"
      assert_select "p del", count: 0
    end

    it "doesn't format highlight tags" do
      markdown_to_html <<~MD
        ==Hello, World!==
      MD

      assert_select "p", "Hello, World!"
      assert_select "p mark", count: 0
    end

    it "doesn't format quote tags" do
      markdown_to_html <<~MD
        This is a "quote"
      MD

      assert_select "p", "This is a quote"
      assert_select "p quote", count: 0
    end

    it "doesn't format superscript tags" do
      markdown_to_html <<~MD
        What is 3^2 ?
      MD

      assert_select "p", "What is 32 ?"
      assert_select "p sup", count: 0
    end
  end

  describe "#markdown_to_text" do
    it "renders a text version" do
      expect(markdown_to_text(
        <<~MD
          Click this link to confirm your email:

          # ((action))

          ((url))

          ---

          ## Next steps

          1. After you have confirmed your email, we will check your
             petition to make sure it meets the petition criteria.

          2. If it does, we’ll publish it and let you know. This usually
             takes a week or less.

          Find out how we check petitions before we publish them:
          ((moderation_info_url))

          Some of the reasons we may not accept your petition are:

          * It's duplicate of an existing petition
          * It's a joke, offensive or libellous
          * It's not the remit of the Scottish Parliament/Government

          Thanks,
          The Public Petitions team
          The Scottish Parliament
        MD
      )).to eq <<~TEXT
        Click this link to confirm your email:

        {{action}}
        ----------
        {{url}}

        =================================================================

        Next steps

        1. After you have confirmed your email, we will check your
        petition to make sure it meets the petition criteria.
        2. If it does, we’ll publish it and let you know. This usually
        takes a week or less.

        Find out how we check petitions before we publish them:
        {{moderation_info_url}}

        Some of the reasons we may not accept your petition are:

        * It's duplicate of an existing petition
        * It's a joke, offensive or libellous
        * It's not the remit of the Scottish Parliament/Government

        Thanks,
        The Public Petitions team
        The Scottish Parliament

      TEXT
    end
  end

  describe "#preheader" do
    it "generates a short text version" do
      expect(preheader(
        <<~MD
          Click this link to confirm your email:

          # ((action))

          ((url))

          ---

          ## Next steps

          1. After you have confirmed your email, we will check your
             petition to make sure it meets the petition criteria.

          2. If it does, we’ll publish it and let you know. This usually
             takes a week or less.

          Find out how we check petitions before we publish them:
          ((moderation_info_url))

          Some of the reasons we may not accept your petition are:

          * It's duplicate of an existing petition
          * It's a joke, offensive or libellous
          * It's not the remit of the Scottish Parliament/Government

          Thanks,
          The Public Petitions team
          The Scottish Parliament
        MD
      )).to eq <<~TEXT.squish
        Click this link to confirm your email: {{action}} {{url}}
        Next steps After you have confirmed your email, we will
        check your petition to make sure it meets the petition
        criteria. If it does, we’ll publish it and let you know.
        This usually takes a week or less. Find out how
      TEXT
    end
  end
end
