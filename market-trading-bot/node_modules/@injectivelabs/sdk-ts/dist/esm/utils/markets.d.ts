export declare const getDerivativeMarketTensMultiplier: ({ quoteDecimals, minPriceTickSize, minQuantityTickSize, }: {
    minPriceTickSize: number | string;
    minQuantityTickSize: number | string;
    quoteDecimals: number;
}) => {
    quantityTensMultiplier: number;
    priceTensMultiplier: number;
};
export declare const getSpotMarketTensMultiplier: ({ baseDecimals, quoteDecimals, minPriceTickSize, minQuantityTickSize, }: {
    minPriceTickSize: number | string;
    minQuantityTickSize: number | string;
    baseDecimals: number;
    quoteDecimals: number;
}) => {
    priceTensMultiplier: number;
    quantityTensMultiplier: number;
};
export declare const getDerivativeMarketDecimals: ({ minPriceTickSize, minQuantityTickSize, quoteDecimals, }: {
    minPriceTickSize: number | string;
    minQuantityTickSize: number | string;
    quoteDecimals: number;
}) => {
    quantityDecimals: number;
    priceDecimals: number;
};
export declare const getSpotMarketDecimals: ({ minPriceTickSize, minQuantityTickSize, baseDecimals, quoteDecimals, }: {
    minPriceTickSize: number | string;
    minQuantityTickSize: number | string;
    baseDecimals: number;
    quoteDecimals: number;
}) => {
    priceDecimals: number;
    quantityDecimals: number;
};
