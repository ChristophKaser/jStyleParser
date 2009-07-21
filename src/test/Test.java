/**
 * Test.java
 *
 * Created on 11.11.2008, 14:29:33 by burgetr
 */
package test;

import java.util.Map;
import java.io.*;
import java.net.*;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.tidy.Tidy;


import cz.vutbr.web.css.*;


/**
 * @author burgetr
 *
 */
public class Test
{
    
    public static void main2(String[] args)
    {
        try {
            StyleSheet ss = CSSFactory.parse("h1 { line-height: 1; }");
            System.out.println("Style:");
            System.out.println(ss);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args)
    {
        try {
            Tidy parser = new Tidy();
            parser.setInputEncoding("utf-8");
            URL url = new URL("file:///home/burgetr/workspace/Layout/test/csstest.html");
            InputStream in = url.openStream();
            Document doc = parser.parseDOM(in, null);
            ElementMap elements = new ElementMap(doc);
            
            Map<Element, NodeData> decl = CSSFactory.assignDOM(doc, url, "screen", true);
            Element el = elements.getElementById("head");
            
            System.out.println("id=" + el.getAttribute("id"));
            NodeData style = decl.get(el);
            System.out.println("Style: " + style);
            
            /*CSSProperty.FontFamily x = style.getProperty("font-family");
            System.out.println("x="+x);
            TermList y = style.getValue(TermList.class, "font-family");
            System.out.println("y="+y);
            for (Term<?> term : y)
            {
                Object value = term.getValue();
                if (value instanceof CSSProperty.FontFamily)
                {
                    CSSProperty.FontFamily fml = (CSSProperty.FontFamily) value;
                    if (fml == CSSProperty.FontFamily.SERIF)
                        System.out.println("cc: " + term);
                    else
                        System.out.println("aa: " + term);
                }
                else
                    System.out.println("bb: " + term);
            }*/
            
            TermLength len = style.getValue(TermLength.class, "font-size");
            System.out.println("len="+len);
            CSSProperty.ListStyleType typ = style.getProperty("list-style-type");
            System.out.println("typ="+typ);
            CSSProperty.ListStyleType pos = style.getProperty("list-style-position");
            System.out.println("pos="+pos);
            
            Declaration dec = CSSFactory.getRuleFactory().createDeclaration();
            dec.unlock();
            dec.setProperty("display");
            dec.setImportant(true);
            //TermLength nlen = CSSFactory.getTermFactory().createLength(10f, Unit.px);
            TermIdent nlen = CSSFactory.getTermFactory().createIdent("block");
            dec.add(nlen);
            style.push(dec);
            
            /*CSSProperty.BorderSpacing prop = style.getProperty("border-spacing");
            System.out.println("prop="+prop);
            TermList val = style.getValue(TermList.class, "border-spacing");
            System.out.println("val="+val);
            TermLength v1 = (TermLength) val.get(0);
            System.out.println("v1="+v1);*/
            
            TermNumber num = style.getValue(TermNumber.class, "line-height");
            System.out.println("ll="+num);
            
            CSSProperty.Margin mm = style.getProperty("margin-top");
            System.out.println("mm="+mm);
            TermLength mtop = style.getValue(TermLength.class, "margin-top");
            System.out.println("mtop="+mtop);
            
            
            
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
        }

    }

}