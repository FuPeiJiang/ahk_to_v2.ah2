	t := A_TimeSincePriorHotkey
	if (A_PriorHotkey = A_ThisHotkey && t < timeout)
	{
		; Remember how many times we've scrolled in the current direction
		distance++

		; Calculate acceleration factor using a 1/x curve
		v := (t < 80 && t > 1) ? (250.0 / t) - 1 : 1

		; Apply boost
		if (boost > 1 && distance > boost)
		{
			; Hold onto the highest speed we've achieved during this boost
			if (v > vmax)
				vmax := v
			else
				v := vmax

			v *= distance / boost
		}

		; Validate
		v := (v > 1) ? ((v > limit) ? limit : Floor(v)) : 1

		if (v > 1 && tooltips)
			QuickToolTip("x"v, timeout)

		MouseClick, %A_ThisHotkey%, , , v
	}
	else
	{
		; Combo broken, so reset session variables
		distance := 0
		vmax := 1

		MouseClick %A_ThisHotkey%
	}
	return
