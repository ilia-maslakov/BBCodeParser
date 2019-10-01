using System;
using System.Collections.Generic;

namespace BBCodeParser
{
    class Entity
    {
        String _id;
        String _value;
        String[] _attr;
        List<Tags> _taglist;

        public string Id { get => _id; set => _id = value; }
        public string Value { get => _value; set => _value = value; }
        public string[] Attr { get => _attr; set => _attr = value; }
        public List<Tags> TagList { get => _taglist; set => _taglist = value; }
    }
    
    enum TagTypes : byte
    {
        None = 0,
        Open = 1,
        Close = 2
    }

    enum Tags {
        NORMAL = 0,
        BOLD,
        STRIKE,
        HEADLINE,
        CODE,
        ITALIC,
        URL,
        QUOTE,
        IMG
    }

    enum PState {
        SearchingTag,
        InTag
    }

    class TagResult
    {
        Tags tag;
        TagTypes type;
        String[] attr;

        public string[] Attr { get => attr; set => attr = value; }
        public Tags Tag { get => tag; set => tag = value; }
        public TagTypes TagType { get => type; set => type = value; }
        public TagResult(Tags Tag, TagTypes tagType, String[] Attr)
        {
            Attr = this.Attr;
            Tag = this.Tag;
            TagType = this.TagType;
        }
    }

    class Program
    {
        static Stack<Tags> OpenedTagStack = new Stack<Tags>();
        static List<Entity> StringList = new List<Entity>();

        static string[] ExtractAttr(String text, Tags tag)
        {
            var url = "";
            var user = "";

            if (tag == Tags.QUOTE)
            {
                String partstr = text.Substring(7, text.Length - 8);

                int pos = partstr.IndexOf(':');
                if (pos == 0)
                {
                    url = "";
                    user = partstr.Substring(1, (partstr.Length - 1));
                }
                else if (pos > 0)
                {
                    url = partstr.Substring(1, pos - 1);
                    user = partstr.Substring(pos + 1, (partstr.Length - pos - 1));
                }
            }
            else if (tag == Tags.URL)
            {
                url = text.Substring(5, text.Length - 6);
            }
            return new string[] { url, user };
        }

        static TagResult IsTag(String text)
        {
            var res = new TagResult(Tags.NORMAL, TagTypes.None, null);
            if (text.Length > 7)
            {
                var new_text = text.Substring(0, 7).ToUpper();
                if (String.Compare(new_text, "[QUOTE=") == 0)
                {
                    res.Tag = Tags.QUOTE;
                    res.TagType = TagTypes.Open;
                    res.Attr = ExtractAttr(text, res.Tag);
                    return res;
                }
            }
            if (text.Length > 4)
            {
                if (String.Compare(text.Substring(0, 5).ToUpper(), "[URL=") == 0)
                {
                    res.Tag = Tags.URL;
                    res.TagType = TagTypes.Open;
                    res.Attr = ExtractAttr(text, res.Tag);
                    return res;
                }
                if (String.Compare(text.Substring(0, 5).ToUpper(), "[IMG=") == 0)
                {
                    res.Tag = Tags.IMG;
                    res.TagType = TagTypes.Open;
                    return res;
                }
            }

            switch (text.ToUpper())
            {
                case "[H]":
                    res.Tag = Tags.HEADLINE;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/H]":
                    res.Tag = Tags.HEADLINE;
                    res.TagType = TagTypes.Close;
                    break;
                case "[B]":
                    res.Tag = Tags.BOLD;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/B]":
                    res.Tag = Tags.BOLD;
                    res.TagType = TagTypes.Close;
                    break;
                case "[S]":
                    res.Tag = Tags.STRIKE;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/S]":
                    res.Tag = Tags.STRIKE;
                    res.TagType = TagTypes.Close;
                    break;
                case "[I]":
                    res.Tag = Tags.ITALIC;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/I]":
                    res.Tag = Tags.ITALIC;
                    res.TagType = TagTypes.Close;
                    break;
                case "[CODE]":
                    res.Tag = Tags.CODE;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/CODE]":
                    res.Tag = Tags.CODE;
                    res.TagType = TagTypes.Close;
                    break;
                case "[IMG]":
                    res.Tag = Tags.IMG;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/IMG]":
                    res.Tag = Tags.IMG;
                    res.TagType = TagTypes.Close;
                    break;
                case "[/URL]":
                    res.Tag = Tags.URL;
                    res.TagType = TagTypes.Close;
                    break;
                case "[URL]":
                    res.Tag = Tags.URL;
                    res.TagType = TagTypes.Open;
                    break;
                case "[QUOTE]":
                    res.Tag = Tags.QUOTE;
                    res.TagType = TagTypes.Open;
                    break;
                case "[/QUOTE]":
                    res.Tag = Tags.QUOTE;
                    res.TagType = TagTypes.Close;
                    break;
                default:
                    res.Tag = Tags.NORMAL;
                    res.TagType = TagTypes.None;
                    break;
            }
            return res;
        }

        static void AddTaggedStr(string text, TagResult Decoration, int index)
        {
            if (Decoration == null)
            {
                throw new ArgumentNullException(nameof(Decoration));
            }
            List<Tags> tmptl = new List<Tags>();
            foreach (var t in OpenedTagStack)
            {
                tmptl.Add(t);
            }
            if (tmptl.Count == 0 && Decoration.Tag != Tags.NORMAL)
            {
                tmptl.Add(Decoration.Tag);
            }
            Entity e = new Entity {
                Id = (Decoration.Tag.ToString() + index.ToString()),
                TagList = tmptl,
                Attr = Decoration.Attr,
                Value = text
            };
            StringList.Add(e);
        }

        static string Parse(string text)
        {
            var state = PState.SearchingTag;
            char ch;
            TagResult tres = IsTag("");
            String stackstr = "";
            for (int i = 0; i < text.Length; i++)
            {
                ch = text[i];
                //Console.Write(text[i]);
                if (state == PState.SearchingTag)
                {
                    if (ch == '[')
                    {
                        state = PState.InTag;
                        AddTaggedStr(stackstr, tres, i);
                        stackstr = "";
                    }
                    if (ch == 'h' && text.Length > i + 8)
                    {
                        //found http(s) signature
                        String foundedUrl = "";
                        if (text[i + 1] == 't' && text[i + 2] == 't' && text[i + 3] == 'p' && text[i + 6] == '/')
                        {
                            if (stackstr.Length > 0)
                            {
                                AddTaggedStr(stackstr, tres, i);
                                stackstr = "";
                            }
                            for (int j = i; j < text.Length; j++)
                            {
                                int nextj = j + 1;
                                if (nextj < text.Length && tres.Tag != Tags.IMG && tres.Tag != Tags.URL)
                                {
                                    foundedUrl = foundedUrl + text[j];
                                    if (text[nextj] == '[')
                                    {
                                        TagResult tmp = IsTag("[url]");
                                        AddTaggedStr(foundedUrl, tmp, i);
                                        Console.WriteLine("нашли [");
                                        break;
                                    }
                                    if (text[nextj] == ' ' || text[nextj] == '\t' || text[nextj] == '\n')
                                    {
                                        TagResult tmp = IsTag("[url]");
                                        AddTaggedStr(foundedUrl, tmp, i);
                                        Console.WriteLine("нашли конец урла");
                                        break;
                                    }
                                }
                            }
                            if (foundedUrl.Length > 1)
                            {
                                stackstr = "";
                                i += foundedUrl.Length;
                                continue;
                            }
                        }
                    }
                }
                stackstr = stackstr + ch;
                if (state == PState.InTag) { 

                    if (ch == ']')
                    {
                        state = PState.SearchingTag;
                        tres = IsTag(stackstr);
                        if (tres.TagType == TagTypes.Open)
                        {
                            OpenedTagStack.Push(tres.Tag);
                        }
                        else if (tres.TagType == TagTypes.Close)
                        {
                            OpenedTagStack.TryPop(out Tags d);
                            if (OpenedTagStack.Count > 0)
                            {
                                var lastTag = OpenedTagStack.Peek();
                                tres.Tag = lastTag;
                            }
                            else
                            {
                                tres.Tag = Tags.NORMAL;
                            }
                            
                        }
                        stackstr = "";
                    }
                }
            }
            return text;
        }
        static void Main(string[] args)
        {
            StringList = new List<Entity>();
            var s = "http://qwerty.com [img=1.com]http://img.com/1.jpg[/img] e[b]ss[/b]r[url=http://werterwt.rwe/3243423][b]fdhfdhgfdhgfdhd[/b][/url][quote=:@wewrew][h]eyter[i]werterw[b]erwterwter[/b]ewtew[/i][/h]werterwtewrtrew[/quote]    [quote=1234321-2134213:@wewrew]1111111111111111[/quote] [quote]22222222222222222[/quote]";
            Console.WriteLine(s);
            Parse(s);
            foreach(var e in StringList)
            {
                if (e != null && e.Value?.Length > 0)
                {
                    Console.WriteLine("[" + e.Value + "]");
                    if (e.Attr != null && e.Attr?.Length > 0)
                    {
                        Console.Write("   attr: ");
                        foreach (var item in e.Attr)
                        {
                            Console.Write(" " + item);
                        }
                        Console.WriteLine();
                    }
                    if (e?.TagList?.Count > 0)
                    {
                        Console.Write("   style: ");
                        foreach (var item in e.TagList)
                        {
                            Console.Write(" " + item);
                        }
                        Console.WriteLine();
                    }
                }
            }
            Console.ReadKey();
        }
    }
}
