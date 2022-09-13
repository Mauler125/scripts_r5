global function SpecialCurrencyShopPanel_Init

struct {
	var        panel
	var        infoBox
	array<var> offerButtons

	ItemFlavor ornull          activeCollectionEvent
	table<var, GRXScriptOffer> offerButtonToOfferMap
	var                        WORKAROUND_currentlyFocusedOfferButtonForFooters
} file

int NUM_OFFER_BUTTONS = 6

void function SpecialCurrencyShopPanel_Init( var panel )
{
}

