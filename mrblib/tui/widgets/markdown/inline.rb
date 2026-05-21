# frozen_string_literal: true

##
# @api private
class TUI::Markdown
  class Inline
    ##
    # @param [Hash] theme
    def initialize(theme:)
      @theme = theme
    end
    
    ##
    # @param [Array<Hash>] nodes
    # @param [Hash, nil] style
    # @param [Array<Hash>] out
    # @return [Array<Hash>]
    def segments(nodes, style = nil, out = [])
      style ||= base_style
      nodes.each do |node|
        type = node_type(node)
        case type
        when :text
          text = inline_text(node)
          out << segment_for(style, text) unless text.empty?
        when :em
          segments(children_of(node), merge_style(style, italic: true), out)
        when :strong
          segments(children_of(node), merge_style(style, bold: true), out)
        when :underline
          segments(children_of(node), merge_style(style, underline: true), out)
        when :code
          segments(children_of(node), merge_style(style, fg: @theme[:code_fg], bg: @theme[:code_bg]), out)
        when :link
          segments(children_of(node), merge_style(style, fg: @theme[:link_fg], underline: true), out)
        else
          segments(children_of(node), style, out)
        end
      end
      out
    end

    ##
    # @param [Hash, nil] node
    # @return [String]
    def plain_text(node)
      return "" if node.nil?
      if node_type(node) == :text
        return "\n" if node[:text_type] == :br || node[:text_type] == :softbreak
        return node[:text].to_s
      end
      text = +""
      children_of(node).each do |child|
        text << plain_text(child)
      end
      text
    end

    ##
    # @param [Hash, nil] node
    # @return [Array<Hash>]
    def children_of(node)
      return [] unless node.is_a?(Hash)
      children = node[:children]
      children.is_a?(Array) ? children : []
    end

    ##
    # @param [Hash, nil] node
    # @return [Symbol, nil]
    def node_type(node)
      node.is_a?(Hash) ? node[:type] : nil
    end

    ##
    # @param [Hash] node
    # @return [Boolean]
    def inline_container?(node)
      type = node_type(node)
      type == :text || type == :em || type == :strong || type == :underline ||
        type == :code || type == :link
    end

    ##
    # @param [Hash] style
    # @param [Hash] overrides
    # @return [Hash]
    def merge_style(style, overrides)
      value = style.dup
      overrides.each do |key, entry|
        value[key] = entry
      end
      value
    end

    ##
    # @return [Hash]
    def base_style
      {fg: @theme[:fg], bg: @theme[:bg], bold: false, italic: false, underline: false}
    end

    private

    ##
    # @api private
    # @param [Hash] node
    # @return [String]
    def inline_text(node)
      case node[:text_type]
      when :br, :softbreak
        "\n"
      else
        node[:text].to_s
      end
    end

    ##
    # @api private
    # @param [Hash] style
    # @param [String] text
    # @return [Hash]
    def segment_for(style, text)
      {
        text: text,
        fg: style[:fg] || @theme[:fg],
        bg: style[:bg] || @theme[:bg],
        bold: !!style[:bold],
        italic: !!style[:italic],
        underline: !!style[:underline]
      }
    end
  end
end
