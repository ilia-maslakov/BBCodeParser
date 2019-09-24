import 'dart:collection';

enum TagTypes { None, Open, Close }

enum Tags { NORMAL, BOLD, STRIKE, HEADLINE, CODE, ITALIC, URL, QUOTE, IMG }

enum PState { SearchingTag, InTag }

List<Entity> stringList = new List<Entity>();

class Entity {
  String id;
  String value;
  List<String> attr;
  List<Tags> tagList;

  Entity(this.id, this.value, this.attr, this.tagList);
}

class TagResult {
  Tags tag;
  TagTypes tagType;
  List<String> attr;

  TagResult(this.tag, this.tagType);
}

class Parser {
  static var openedTagStack = new Queue();

  static List<String> extractAttr(String text, Tags tag) {
    var url = "";
    var user = "";

    if (tag == Tags.QUOTE) {
      String partstr = text.substring(7, text.length-1);

      int pos = partstr.indexOf(':');
      if (pos == 0) {
        url = "";
        user = partstr.substring(1, partstr.length);
      } else if (pos > 0) {
        url = partstr.substring(1, pos - 1);
        user = partstr.substring(pos + 1, partstr.length-1);
      }
    } else if (tag == Tags.URL) {
      url = text.substring(5, text.length - 1);
    }
    var res = new List<String>();
    res.add(url);
    res.add(user);
    return res;
  }

  static TagResult thisTagIs(String text) {
    var res = new TagResult(Tags.NORMAL, TagTypes.None);
    if (text.length > 7) {
      var s = text.substring(0, 7).toUpperCase();
      if (s == "[QUOTE=") {
        res.tag = Tags.QUOTE;
        res.tagType = TagTypes.Open;
        res.attr = extractAttr(text, res.tag);
        return res;
      }
    }
    if (text.length > 4) {
      var s = text.substring(0, 5).toUpperCase();
      if (s == "[URL=") {
        res.tag = Tags.URL;
        res.tagType = TagTypes.Open;
        res.attr = extractAttr(text, res.tag);
        return res;
      }
    }

    switch (text.toUpperCase()) {
      case "[H]":
        res.tag = Tags.HEADLINE;
        res.tagType = TagTypes.Open;
        break;
      case "[/H]":
        res.tag = Tags.HEADLINE;
        res.tagType = TagTypes.Close;
        break;
      case "[B]":
        res.tag = Tags.BOLD;
        res.tagType = TagTypes.Open;
        break;
      case "[/B]":
        res.tag = Tags.BOLD;
        res.tagType = TagTypes.Close;
        break;
      case "[S]":
        res.tag = Tags.STRIKE;
        res.tagType = TagTypes.Open;
        break;
      case "[/S]":
        res.tag = Tags.STRIKE;
        res.tagType = TagTypes.Close;
        break;
      case "[I]":
        res.tag = Tags.ITALIC;
        res.tagType = TagTypes.Open;
        break;
      case "[/I]":
        res.tag = Tags.ITALIC;
        res.tagType = TagTypes.Close;
        break;
      case "[CODE]":
        res.tag = Tags.CODE;
        res.tagType = TagTypes.Open;
        break;
      case "[/CODE]":
        res.tag = Tags.CODE;
        res.tagType = TagTypes.Close;
        break;
      case "[IMG]":
        res.tag = Tags.IMG;
        res.tagType = TagTypes.Open;
        break;
      case "[/IMG]":
        res.tag = Tags.IMG;
        res.tagType = TagTypes.Close;
        break;
      case "[/URL]":
        res.tag = Tags.URL;
        res.tagType = TagTypes.Close;
        break;
      case "[QUOTE]":
        res.tag = Tags.QUOTE;
        res.tagType = TagTypes.Open;
        break;
      case "[/QUOTE]":
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

    List<Tags> tmpTL = new List<Tags>();
    openedTagStack.forEach((value) {
      tmpTL.add(value);
    });

    Entity e = new Entity(decoration.tag.toString() + index.toString(), text, decoration.attr, tmpTL);
    stringList.add(e);
  }

  static List<Entity> parse(String text)
  {

    var state = PState.SearchingTag;
    var ch;
    TagResult tres = thisTagIs("");
    String stackstr = "";
    for (int i = 0; i < text.length; i++)
    {
      ch = text[i];
      if (state == PState.SearchingTag && (ch == '[' || i == (text.length - 1))) {
        state = PState.InTag;
        addTaggedStr(stackstr, tres, i);
        stackstr = "";
      }
      stackstr = stackstr + ch;
      if (state == PState.InTag) {

        if (ch == ']')
        {
          state = PState.SearchingTag;
          tres = thisTagIs(stackstr);
          if (tres.tagType == TagTypes.Open)
          {
            openedTagStack.add(tres.tag);
          }
          else if (tres.tagType == TagTypes.Close)
          {
            if (openedTagStack.length > 0) {
              openedTagStack.removeLast();
            }
          }
          stackstr = "";
        }
      }
    }
    return stringList;
  }
}
