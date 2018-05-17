package cz.vutbr.web.csskit.fn;

import java.util.List;

import cz.vutbr.web.css.Term;
import cz.vutbr.web.css.TermAngle;
import cz.vutbr.web.css.TermFunction;
import cz.vutbr.web.css.TermList;

public class RepeatingLinearGradientImpl extends GenericGradient implements TermFunction.RepeatingLinearGradient {
    private TermAngle angle;
    
    public RepeatingLinearGradientImpl() {
        setValid(false);
    }
    
    @Override
    public TermAngle getAngle() {
        return angle;
    }

    @Override
    public TermList setValue(List<Term<?>> value) {
        super.setValue(value);
        List<List<Term<?>>> args = getSeparatedArgs(DEFAULT_ARG_SEP);
        if (args.size() > 1) {
            int firstStop = 0;
            //check for an angle
            List<Term<?>> aarg = args.get(0);
            if (aarg.size() == 1 && (angle = getAngleArg(aarg.get(0))) != null) {
                firstStop = 1;
            } else if ((angle = convertSideOrCorner(aarg)) != null) {
                firstStop = 1;
            }
            //check for stops
            loadColorStops(args, firstStop);
            if (getColorStops() != null)
                setValid(true);
        }
        return this;
    }
}