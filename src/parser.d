module parser;
/*
Implement types and functions for recognizing multiword keywords (e.g. "LEFT OUTER JOIN")
*/

import preprocessor;
import higher_types;





/* Element of Parser - basicaly */
struct ParserResult
{
private:
    string[] p_leedingWhitespaces; // spaces,tabs,newlines
    string[] p_leedingComments;
    string p_Text;
    string p_Type;


public:
    @property
    string Text()
    {
        return p_Text;
    }

    /* Construct from preprocessed content and name of the keyword */
    this(PreprocResult[] prep, string kwName="other")
    {
        import std.algorithm;
        import std.array;
        p_leedingWhitespaces = array(joiner(map!"a.leedingWhitespaces"(prep)));
        p_leedingComments    = array(joiner(map!"a.leedingComments"(prep)));
        p_Text      = cast(string) array(joiner(map!"a.tokenText"(prep)," ")); // FIXME - somehow remove cast. for some reason result of rside is of type dchar[]
        p_Type      = kwName;
    }
}





/* InputRange constructed from preprocessed tokens and returning recognized multiword keywords.
   e.g. if constructed from "(LEFT)(JOIN)" returns "(LEFT JOIN)". Also returned structure contains keyword name */
struct Parser
{
private:
    Preprocessor p_preprocessedTokens;
public:
    /* Construct from preprocessed content */
    this(in Preprocessor prep )
    {
        p_preprocessedTokens = prep;
    }

    /* Return multiword keyword found at the front of preprocessed content */
    auto front()
    {
        immutable auto MAX_WORDS=3; // longest SQL keywords that came to mind are joins made of 3 words (e.g. "LEFT OUTER JOIN").

        import std.algorithm;
        import std.range;

        alias higher_types.keywordList k;


        auto sqlTokens = array(take(map!"a.tokenText"(p_preprocessedTokens),MAX_WORDS));

        /* loop to find keyword which matches something from the front of the input */
        foreach(kw ; k.values)
        {
            auto wordCount = kw.matchedWordcount(sqlTokens);
            if(wordCount > 0)
            {
                return ParserResult(array(take(p_preprocessedTokens,wordCount)), kw.kwName);
            }
        }

        // if nothing matched then just take 1 front token
        return ParserResult(array(take(p_preprocessedTokens,1)));
    }


    /* Drop content used for result of front(), so next call to front() would return new multiword keyword */
    void popFront()
    {
        import std.array;
        auto cached_front = this.front();
        if(cached_front.p_Type != "other")
        {
            for(auto i = split(cached_front.p_Text).length ; i>0 ; --i) // pop for each matched word
            {
                p_preprocessedTokens.popFront();
            }
        }
        else
        {
            p_preprocessedTokens.popFront();
        }
    }


    /* Return TRUE if no more elements can be returned (end of input was reached) */
    @property
    bool empty()
    {
        return p_preprocessedTokens.empty();
    }


    /*  Convert Tokenizer to string. At the moment for debuging purposes */
    string toString()
    {
        import std.algorithm;
        return std.algorithm.reduce!q{a~"("~b.Text~")"}("",this);
    }
}