// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract DynamicSvgNft is ERC721{
   
   uint256 private s_tokenCounter;
   string private s_lowImageURI;
   string private s_highImageURI;
   string private constant base64EncodeedSvgPrefix="data:image/svg+xml;base64,";
   
   mapping(uint256 => int256) private s_tokenIdToHighValues; 
   AggregatorV3Interface internal immutable i_priceFeed;
   event CreatedNFT(uint256 indexed tokenId, int256 highValue);

   constructor(
    address priceFeedAddress,
    string memory lowSvg,
    string memory highSvg
   )ERC721("Dynamic SVG NFT", "DSN"){
      s_tokenCounter = 0;
      i_priceFeed = AggregatorV3Interface(priceFeedAddress);
      s_lowImageURI = svgToImageURI(lowSvg);
      s_highImageURI = svgToImageURI(highSvg);
   }

   function mintNft(int256 highValue) public {
     s_tokenIdToHighValues[s_tokenCounter] = highValue;
     _safeMint(msg.sender, s_tokenCounter);
     s_tokenCounter = s_tokenCounter + 1;
     emit CreatedNFT(s_tokenCounter, highValue);
   }


   function svgToImageURI(string memory svg) public pure returns (string memory) {
      //   string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(base64EncodeedSvgPrefix, svgBase64Encoded));
   }

   function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"URI Query for nonexistent token");
      (, int256 price, , , ) = i_priceFeed.latestRoundData();
      string memory imageURI = s_lowImageURI;
      if (price >= s_tokenIdToHighValues[tokenId]) {
            imageURI = s_highImageURI;
      }
      //   string memory imageURI="hi!";
     
        return string(
                abi.encodePacked(
                   // 拼接 _baseURI()+ Base64
                    _baseURI(),Base64.encode( 
                      bytes(
                              abi.encodePacked(
                              //将这些都拼接在一起
                                  '{"name":"',
                                  name(), // You can add whatever name here
                                  '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                  '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                  imageURI,
                                  '"}'
                              )
                            )
                    )
                )
            );
   }
}