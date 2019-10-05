import 'dart:collection';

enum TagTypes { None, Open, Close }

enum Tags { NORMAL, BOLD, STRIKE, HEADLINE, CODE, ITALIC, URL, QUOTE, IMG }

enum PState { SearchingTag, InTag }

List<Entity> stringList = new List<Entity>();

class Entity {
  String id;
  String value;
  Map<String, String> attr;
  List<Tags> tagList;

  Entity(this.id, this.value, this.attr, this.tagList);
}

class TagResult {
  Tags tag;
  TagTypes tagType;
  Map<String, String> attr;

  TagResult(this.tag, this.tagType);
}

class Parser {
  static var openedTagStack = new Queue();

  static Map<String, String> extractAttr(String text, Tags tag) {
    var url = '';
    var user = '';

    if (tag == Tags.QUOTE) {
      String partstr = text.substring(7, text.length - 1);
      int pos = partstr.indexOf(':');
      if (pos == 0) {
        url = '';
        user = partstr.substring(1, partstr.length);
      } else if (pos > 0) {
        url = partstr.substring(0, pos);
        user = partstr.substring(pos + 2, partstr.length);
      }
    } else if (tag == Tags.URL) {
      url = text.substring(5, text.length - 1);
      user = "";
    }
    var res = {'user': user, 'url': url};
    return res;
  }

  static TagResult thisTagIs(String text) {
    var res = new TagResult(Tags.NORMAL, TagTypes.None);
    if (text.length > 7) {
      var s = text.substring(0, 7).toUpperCase();
      if (s == '[QUOTE=') {
        res.tag = Tags.QUOTE;
        res.tagType = TagTypes.Open;
        res.attr = extractAttr(text, res.tag);
        return res;
      }
    }
    if (text.length > 4) {
      var s = text.substring(0, 5).toUpperCase();
      if (s == '[URL=') {
        res.tag = Tags.URL;
        res.tagType = TagTypes.Open;
        res.attr = extractAttr(text, res.tag);
        return res;
      } else if (s == '[IMG=') {
        res.tag = Tags.IMG;
        res.tagType = TagTypes.Open;
        return res;
      }
    }

    switch (text.toUpperCase()) {
      case '[H]':
        res.tag = Tags.HEADLINE;
        res.tagType = TagTypes.Open;
        break;
      case '[/H]':
        res.tag = Tags.HEADLINE;
        res.tagType = TagTypes.Close;
        break;
      case '[B]':
        res.tag = Tags.BOLD;
        res.tagType = TagTypes.Open;
        break;
      case '[/B]':
        res.tag = Tags.BOLD;
        res.tagType = TagTypes.Close;
        break;
      case '[S]':
        res.tag = Tags.STRIKE;
        res.tagType = TagTypes.Open;
        break;
      case '[/S]':
        res.tag = Tags.STRIKE;
        res.tagType = TagTypes.Close;
        break;
      case '[I]':
        res.tag = Tags.ITALIC;
        res.tagType = TagTypes.Open;
        break;
      case '[/I]':
        res.tag = Tags.ITALIC;
        res.tagType = TagTypes.Close;
        break;
      case '[CODE]':
        res.tag = Tags.CODE;
        res.tagType = TagTypes.Open;
        break;
      case '[/CODE]':
        res.tag = Tags.CODE;
        res.tagType = TagTypes.Close;
        break;
      case '[IMG]':
        res.tag = Tags.IMG;
        res.tagType = TagTypes.Open;
        break;
      case '[/IMG]':
        res.tag = Tags.IMG;
        res.tagType = TagTypes.Close;
        break;
      case '[/URL]':
        res.tag = Tags.URL;
        res.tagType = TagTypes.Close;
        break;
      case '[URL]':
        res.tag = Tags.URL;
        res.tagType = TagTypes.Open;
        break;
      case '[QUOTE]':
        res.tag = Tags.QUOTE;
        res.tagType = TagTypes.Open;
        break;
      case '[/QUOTE]':
        res.tag = Tags.QUOTE;
        res.tagType = TagTypes.Close;
        break;
      default:
        res.tag = Tags.NORMAL;
        res.tagType = TagTypes.None;
        break;
    }
    return res;
  }

  static void addTaggedStr(String text, TagResult decoration, int index) {
    if (decoration == null) {
      return;
    }
    print('PARSED $text');
    List<Tags> tmpTL = new List<Tags>();
    openedTagStack.forEach((value) {
      tmpTL.add(value);
    });
    if (openedTagStack.isEmpty && decoration.tag != Tags.NORMAL) {
      tmpTL.add(decoration.tag);
    }
    Entity e = new Entity(decoration.tag.toString() + index.toString(), text, decoration.attr, tmpTL);
    stringList.add(e);
  }
  static bool isEndUrl(String ch) {
    if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '[' || ch == ']' || ch == '(' || ch == ')') {
      return true;
    }
    return false;
  }

  static List<Entity> parse(String text) {
    var state = PState.SearchingTag;
    var ch;
    print('RAW $text');
    stringList.clear();
    TagResult tres = thisTagIs('');
    String stackstr = '';
    for (int i = 0; i < text.length; i++) {
      ch = text[i];
      if (state == PState.SearchingTag) {
        if (ch == '[') {
          state = PState.InTag;
          if (stackstr.length > 0) {
            addTaggedStr(stackstr, tres, i);
            stackstr = '';
          }
        } else if (ch == 'h' && text.length > (i + 8) && tres.tag != Tags.IMG && tres.tag != Tags.URL) {
          //found http(s) signature
          String foundedUrl = '';
          if (text[i + 1].toLowerCase() == 't' && text[i + 2].toLowerCase() == 't' && text[i + 3].toLowerCase() == 'p' && text[i + 6].toLowerCase() == '/') {
            if (stackstr.length > 0) {
              addTaggedStr(stackstr, tres, i);
              stackstr = '';
            }
            for (int j = i; j < text.length && !isEndUrl(text[j]); j++) {
              foundedUrl = foundedUrl + text[j];
            }
            if (foundedUrl.length > 1) {
              TagResult tmp = thisTagIs('[url]');
              addTaggedStr(foundedUrl, tmp, i);
              i += foundedUrl.length - 1;
              foundedUrl = '';
              stackstr = '';
              continue;
            }
          }
        }
      }
      stackstr = stackstr + ch;
      if (PState.InTag == state) {
        if (ch == ']') {
          state = PState.SearchingTag;
          tres = thisTagIs(stackstr);
          if (tres.tagType == TagTypes.Open) {
            openedTagStack.add(tres.tag);
          } else if (tres.tagType == TagTypes.Close) {
            if (openedTagStack.length > 0) {
              openedTagStack.removeLast();
              if (openedTagStack.length > 0) {
                tres.tag = openedTagStack.last;
              } else {
                tres.tag = Tags.NORMAL;
              }
            }
          }
          stackstr = '';
        }
      }
    }
    if (stackstr.length > 0) {
      addTaggedStr(stackstr, tres, stackstr.length);
    }
    return stringList;
  }
}
