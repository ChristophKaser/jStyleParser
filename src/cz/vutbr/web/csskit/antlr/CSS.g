grammar CSS;

options {
	output = AST;
	k = 2;
}

tokens {
	STYLESHEET;
	ATBLOCK;
	CURLYBLOCK;
	PARENBLOCK;
	BRACEBLOCK;
	RULE;	
	SELECTOR;
	ELEMENT;
	PSEUDO;
	ADJACENT;
	CHILD;
	DESCENDANT;
	ATTRIBUTE;
	DECLARATION;	
	VALUE;
	IMPORTANT;
	
	INVALID_DECLARATION;
}



@parser::header { 
package cz.vutbr.web.csskit.antlr;

import org.apache.log4j.Logger;
}

@lexer::header {
package cz.vutbr.web.csskit.antlr;

import java.util.Stack;

import org.apache.log4j.Logger;

}

@lexer::members {
    private static Logger log = Logger.getLogger(CSSLexer.class);
    
    // level of curly block nesting
    private int curlyNest = 0;

    private Stack<StreamPosition> imports = new Stack<StreamPosition>();

    class StreamPosition {
        public CharStream input;
        public int mark;
        
    	public StreamPosition(CharStream input) {
    	    this.input = input;
    	    this.mark = input.mark();	
    	}
    }	
    
    /**
     * Overrides next token to match includes and to 
     * recover from EOF
     */
	@Override 
    public Token nextToken(){
       Token token = super.nextToken();

       // recover from unexpected EOF
       if(token==Token.EOF_TOKEN && curlyNest!=0) {
           token = new CommonToken(input, RCURLY, state.channel, state.tokenStartCharIndex, getCharIndex()-1);
           token.setLine(state.tokenStartLine);
           token.setText("}");
           token.setCharPositionInLine(state.tokenStartCharPositionInLine);
           if(log.isDebugEnabled()) {
           	log.debug("Recovering from unexpected EOF, " + token + ", nest: " + curlyNest);           	
           }           		
           curlyNest--;
           return token;
       }

       if(token==Token.EOF_TOKEN && !imports.empty()){
        // We've got EOF and have non empty stack.
         StreamPosition ss = imports.pop();
         setCharStream(ss.input);
         input.rewind(ss.mark);
         token = super.nextToken();
       }       

      // Skip first token after switching on another input.
      // You need to use this rather than super as there may be nested include files
       if(((CommonToken)token).getStartIndex() < 0)
         token = this.nextToken();

       return token;
     }

	@Override
    public void emitErrorMessage(String msg) {
	if(log.isInfoEnabled()) {
	    log.info("ANTLR: " + msg);
	}
    }
}

@parser::members {
    private static Logger log = Logger.getLogger(CSSParser.class);

    @Override
    public void emitErrorMessage(String msg) {
		if(log.isInfoEnabled()) {
		    log.info("ANTLR: " + msg);
		}
	}
	
    /**
     * Constructs pretty indented "lisp" representation of tree
     * which was created by parser
     */
    public String toStringTree(CommonTree tree) {
        StringBuilder sb = new StringBuilder();
        rec(tree, sb, 0);
        return sb.toString();       
    }

	/**
	 * Recovers and logs error, prepares tree part replacement
	 */ 
	private Object invalidFallback(int ttype, String ttext, RecognitionException re) {
	    reportError(re);
		recover(input, re);
		Object retval = ((CSSAdaptor) adaptor).invalidFallback(ttype, ttext);
		if(log.isTraceEnabled()) {
			log.trace("Replacing in fallback with: " + toStringTree((CommonTree) retval));					 
		}
		return retval;
	}
    
    private void rec(CommonTree tree, StringBuilder sb, int nest) {
        if(tree.getChildCount()==0) {
            addTree(sb, tree, nest);
            return;
        }
            
        if(!tree.isNil()) {
            addTree(sb, tree, nest);
        }
       
        for(int i=0; i < tree.getChildCount(); i++) {
            CommonTree n = (CommonTree) tree.getChild(i);
            rec(n, sb, nest+1);
        }
        if(!tree.isNil()) {
            sb.append(")");
        }
    
    }
    
    private StringBuilder addTree(StringBuilder sb, CommonTree tree, int nest) {
        sb.append("\n");
        for(int i=0; i< nest; i++) {
            sb.append("  ");
        }
        
        if(!tree.isNil())
          sb.append("(");
        
        sb.append(tree.toString()).append(" |")
          .append(tree.getType()).append("| ");
        
        return sb;
    }

}


stylesheet  
	: ( CDO | CDC | S | statement )* 
	-> ^(STYLESHEET statement*)
	;
	
statement   
	: ruleset | atrule
	;
	
atrule     
	: ATKEYWORD S* 
	  any* 
	  ( block | SEMICOLON )
	  -> ^(ATBLOCK ATKEYWORD any* block?)
	;
	
block       
	: LCURLY S* 
		blockpart* 
	  RCURLY 
	  -> ^(CURLYBLOCK blockpart*)
	;

blockpart
    : any -> any 
    | LCURLY S* declaration? (SEMICOLON S* declaration? )* RCURLY S* -> ^(CURLYBLOCK declaration*)
    | (ATKEYWORD S*) -> ATKEYWORD 
    | (SEMICOLON S*) -> SEMICOLON
    ;
  	
	
ruleset     
	: combined_selector (COMMA S* combined_selector)* 
	  LCURLY S* 
	  	declaration? (SEMICOLON S* declaration? )* 
	  RCURLY
	  -> ^(RULE combined_selector+ declaration*)
	;

declaration
	: property COLON S* terms important? -> ^(DECLARATION important? property terms)
	;
	catch [RecognitionException re] {
	  retval.tree = invalidFallback(CSSLexer.INVALID_DECLARATION, "INVALID_DECLARATION", re);									
	}

important
    : EXCLAMATION S* 'important' S* -> IMPORTANT
    ;	
	
property    
	: IDENT S* -> IDENT
	;
	
terms	       
	: term+
	-> ^(VALUE term+)
	;
	
term
    : valuepart -> valuepart
    | LCURLY S* (any | SEMICOLON S*)* RCURLY -> CURLYBLOCK
    | ATKEYWORD S* -> ATKEYWORD
    ;	

valuepart
    : ( IDENT -> IDENT
      | CLASSKEYWORD -> CLASSKEYWORD
      | MINUS? NUMBER -> MINUS? NUMBER
      | MINUS? PERCENTAGE -> MINUS? PERCENTAGE
      | MINUS? DIMENSION -> MINUS? DIMENSION
      | STRING -> STRING
      | URI    -> URI
      | HASH -> HASH
      | UNIRANGE -> UNIRANGE
      | INCLUDES -> INCLUDES
      | COLON -> COLON
      | COMMA -> COMMA
      | GREATER -> GREATER
      | EQUALS -> EQUALS
      | SLASH -> SLASH
	  | PLUS -> PLUS
	  | ASTERISK -> ASTERISK		 
      | FUNCTION S* terms RPAREN -> ^(FUNCTION terms) 
      | DASHMATCH -> DASHMATCH
      | LPAREN valuepart* RPAREN -> ^(PARENBLOCK valuepart*)
      | LBRACE valuepart* RBRACE -> ^(BRACEBLOCK valuepart*)
    ) !S*
  ;

combined_selector    
	: selector ((combinator) selector)*
	;

combinator
	: GREATER S* -> CHILD
	| PLUS S* -> ADJACENT
	| S -> DESCENDANT
	;

selector
    : (IDENT | ASTERISK)  selpart* S*
    	-> ^(SELECTOR ^(ELEMENT IDENT?) selpart*)
    | selpart+ S*
        -> ^(SELECTOR selpart+)
  ;

selpart	
    : COLON IDENT -> PSEUDO IDENT
    | HASH
    | CLASSKEYWORD
	| LBRACE S* attribute RBRACE -> ^(ATTRIBUTE attribute)
    | COLON FUNCTION S* IDENT RPAREN -> ^(FUNCTION IDENT)
    ;
	

attribute
	: IDENT S*
	  ((EQUALS | INCLUDES | DASHMATCH) S* (IDENT | STRING) S*)?
	;
	
any
	: ( IDENT -> IDENT
	  | CLASSKEYWORD -> CLASSKEYWORD
	  | NUMBER -> NUMBER
	  | PERCENTAGE ->PERCENTAGE
	  | DIMENSION -> DIMENSION
	  | STRING -> STRING
      | URI    -> URI
      | HASH -> HASH
      | UNIRANGE -> UNIRANGE
      | INCLUDES -> INCLUDES
      | COLON -> COLON
      | COMMA -> COMMA
      | GREATER -> GREATER
      | EQUALS -> EQUALS
      | SLASH -> SLASH
      | EXCLAMATION -> EXCLAMATION
	  | MINUS -> MINUS
	  | PLUS -> PLUS
	  | ASTERISK -> ASTERISK		 
      | FUNCTION S* any* RPAREN -> ^(FUNCTION any*) 
      | DASHMATCH -> DASHMATCH
      | LPAREN any* RPAREN -> ^(PARENBLOCK any*)
      | LBRACE any* RBRACE -> ^(BRACEBLOCK any*)
    ) !S*;


/////////////////////////////////////////////////////////////////////////////////
// TOKENS //
/////////////////////////////////////////////////////////////////////////////////

/** Identifier */
IDENT	
	: IDENT_MACR
	;	

/** Keyword beginning with '@' */
ATKEYWORD
	: '@' IDENT_MACR
	;

CLASSKEYWORD
    : '.' IDENT_MACR
    ;

/** String including 'decorations' */
STRING
	: STRING_MACR
	;

/** Hash, either color or other */
HASH
	: '#' NAME_MACR	
	;

/** Number, decimal or integer */
NUMBER
	: NUMBER_MACR
	;

/** Number with percent sign */
PERCENTAGE
	: NUMBER_MACR '%'
	;

/** Number with other unit */
DIMENSION
	: NUMBER_MACR IDENT_MACR
	;

/** URI encapsulated in 'url(' ... ')' */
URI
	: 'url(' W_MACR (STRING_MACR | URI_MACR) W_MACR ')'
	;

/** Unicode range */	
UNIRANGE:	
	'U+' ('0'..'9' | 'a'..'f' | 'A'..'F' | '?')
	     ('0'..'9' | 'a'..'f' | 'A'..'F' | '?')
	     ('0'..'9' | 'a'..'f' | 'A'..'F' | '?')
	     ('0'..'9' | 'a'..'f' | 'A'..'F' | '?')
	     (('0'..'9' | 'a'..'f' | 'A'..'F' | '?') ('0'..'9' | 'a'..'f' | 'A'..'F' | '?'))?
	('-'
	     ('0'..'9' | 'a'..'f' | 'A'..'F')
	     ('0'..'9' | 'a'..'f' | 'A'..'F')
             ('0'..'9' | 'a'..'f' | 'A'..'F')
             ('0'..'9' | 'a'..'f' | 'A'..'F')
             (('0'..'9' | 'a'..'f' | 'A'..'F') ('0'..'9' | 'a'..'f' | 'A'..'F'))?
	)?
	;

/** Comment opening */
CDO
	: '<!--'
	;

/** Comment closing */
CDC
	: '-->'
	;	

SEMICOLON
	: ';'
	;

COLON
	: ':'
	;
	
COMMA
    : ','
    ;

EQUALS
    : '='
    ;

SLASH
    : '/'
    ;

GREATER
    : '>'
    ;    	

LCURLY
	: '{'  {curlyNest++;}
	;

RCURLY	
	: '}'  {curlyNest--;}
	;

LPAREN
	: '('
	;

RPAREN
	: ')'
	;		

LBRACE
	: '['
	;

RBRACE
	: ']'
	;
	
EXCLAMATION
    : '!'
    ;	

MINUS
	: '-'
	;

PLUS
	: '+'
	;

ASTERISK
	: '*'
	;

/** White character */		
S
	: W_CHAR+
	;

COMMENT	
	: '/*' ( options {greedy=false;} : .)* '*/' { $channel = HIDDEN; }
	;

SL_COMMENT
	: '//' ( options {greedy=false;} : .)* ('\n' | '\r' ) { $channel=HIDDEN; }
	;		
	
/** Function beginning */	
FUNCTION
	: IDENT_MACR '('
	;

INCLUDES
	: '~='
	;

DASHMATCH
	: '|='
	;

/*********************************************************************
 * FRAGMENTS *
 *********************************************************************/

fragment 
IDENT_MACR
  	: NAME_START NAME_CHAR*
  	;

fragment 
NAME_MACR
 	: NAME_CHAR+
  	;

fragment 
NAME_START
  	: ('a'..'z' | 'A'..'Z' | NON_ASCII | ESCAPE_CHAR)
  	;     

fragment 
NON_ASCII
  	: ('\u0080'..'\uD7FF' | '\uE000'..'\uFFFD')
  	;

fragment 
ESCAPE_CHAR
 	: ('\\') 
 	  (
 	    (('0'..'9' | 'a'..'f' | 'A'..'F')
 	     ('0'..'9' | 'a'..'f' | 'A'..'F')
 	     ('0'..'9' | 'a'..'f' | 'A'..'F')
 	     ('0'..'9' | 'a'..'f' | 'A'..'F')
 	     (('0'..'9' | 'a'..'f' | 'A'..'F') ('0'..'9' | 'a'..'f' | 'A'..'F'))?
 	    )
 	     
 	   |('\u0020'..'\u007E' | '\u0080'..'\uD7FF' | '\uE000'..'\uFFFD')
 	  )
  	;

fragment 
NAME_CHAR
  	: ('a'..'z' | 'A'..'Z' | '0'..'9' | '-' | NON_ASCII | ESCAPE_CHAR)
  	;

fragment 
NUMBER_MACR
  	: ('0'..'9')+ | (('0'..'9')* '.' ('0'..'9')+)
  	;

fragment 
STRING_MACR
	: '"' (STRING_CHAR | '\'')* '"' 
	| '\'' (STRING_CHAR | '"')* '\''
  	;

fragment
STRING_CHAR
	:  (URI_CHAR | ' ' | ('\\' NL_CHAR))
	;
  	
fragment
URI_MACR
	: URI_CHAR*
	;  	
  	
fragment
URI_CHAR
	: ('\u0009' | '\u0021' | '\u0023'..'\u0026' | '\u0028'..'\u007E')
	  | NON_ASCII | ESCAPE_CHAR
	;	

fragment 
NL_CHAR
  	: '\u000A' | '\u000D' '\u000A' | '\u000D' | '\u000C'
  	; 

fragment
W_MACR
	: W_CHAR*
	;

fragment 
W_CHAR
  	: '\u0009' | '\u000A' | '\u000C' | '\u000D' | '\u0020'
  	;