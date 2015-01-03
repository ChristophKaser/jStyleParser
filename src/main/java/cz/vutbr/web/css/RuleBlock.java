package cz.vutbr.web.css;

/**
 * Special case of rule, where rule is meant to be comparable
 * with other rules to determine priority of CSS declarations
 * @author kapy
 *
 * @param <T> Internal content of rule
 */
public interface RuleBlock<T> extends Rule<T>, Comparable<RuleBlock<?>> {

	/**
	 * Sets the owner style sheet for this rule.
	 * @param sheet The stylesheet where this rule is contained.
	 */
	public void setStyleSheet(StyleSheet sheet);
	
	/**
	 * Returns the stylesheet where the rule is contained.
	 * @return The stylesheet.
	 */
	public StyleSheet getStyleSheet();
	
    /**
     * Sets the order of the rule in the style sheet.
     * @param order the order (0 for the first rule etc.)
     */
    public void setOrder(int order);
    
    /**
     * Obtains the order of the rule in the style sheet.
     * @return the order of the rule or -1 when not set
     */
	public int getOrder();
	
}
