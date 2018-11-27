pragma solidity ^0.4.7;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

/* @dev This contract represents the database to store all handlers and products of the
   TODO put name of platform ** platform.  */

contract Database is owned {
  // @dev addresses of the Products referenced in this database
  address[] public products;

  // @dev struct which represents a Handler for the products stored in the database.
  struct Handler {
    // @dev indicates the name of a Handler.
    string _name;
    // @dev Additional information about the Handler, generally as a JSON object
    string _additionalInformation;
    
    address[] _ownerProducts;
  }

  // @dev Relates an address with a Handler record.
  mapping(address => Handler) public addressToHandler;

  /* @notice Constructor to create a Database */
  function Database() public {}

  function () public {
    // If anyone wants to send Ether to this contract, the transaction gets rejected
    throw;
  }

  /* @notice Function to add a Handler reference
     @param _address address of the handler
     @param _name The name of the Handler
     @param _additionalInformation Additional information about the Product,
            generally as a JSON object. */
  function addHandler(address _address, string _name, string _additionalInformation, address[] _ownerProducts) public onlyOwner {
    Handler memory handler;
    handler._name = _name;
    handler._additionalInformation = _additionalInformation;
    handler._ownerProducts = _ownerProducts;

    addressToHandler[_address] = handler;
  }
  
  function getHandler(address _address) view public returns(string,string,address[]){
        return (addressToHandler[_address]._name,addressToHandler[_address]._additionalInformation,addressToHandler[_address]._ownerProducts);
    }

  /* @notice Function to add a product reference
     @param productAddress address of the product */
  function storeProductReference(address productAddress) public {
    products.push(productAddress);
  }
  
  function getAllProducts() view public returns(address[]) {
        return products;
    }

}


 /* @dev Constructor for a Product */
contract Product {
  // @dev Reference to its database contract.
  address public DATABASE_CONTRACT;
  // @dev Reference to its product factory.
  address public PRODUCT_FACTORY;

  // @dev This struct represents an action realized by a handler on the product.
  struct Action {
    //@dev address of the individual or the organization who realizes the action.
    address handler;
    //@dev description of the action.
    string description;
    
    address owner;

    // @dev Instant of time when the Action is done.
    uint timestamp;
    // @dev Block when the Action is done.
    uint blockNumber;
  }

  // @dev if the Product is consumed the transaction can't be done.
  modifier notConsumed {
    if (isConsumed)
      throw;
    _;
  }

  // @dev addresses of the products which were used to build this Product.
  //address[] public parentProducts;
  // @dev addresses of the products which are built by this Product.
  address[] public childProducts;

  // @dev indicates if a product has been consumed or not.
  bool public isConsumed;

  // @dev indicates the name of a product.
  string public name;

  // @dev Additional information about the Product, generally as a JSON object
  string public additionalInformation;

  // @dev all the actions which have been applied to the Product.
  Action[] public actions;

    /////////////////
   // Constructor //
  /////////////////

  /* @notice Constructor to create a Product
     @param _name The name of the Product
     @param _additionalInformation Additional information about the Product,
            generally as a JSON object.
     @param _ownerProducts Addresses of the owner of the Product.
     @param _DATABASE_CONTRACT Reference to its database contract
     @param _PRODUCT_FACTORY Reference to its product factory */
  function Product(string _name, string _additionalInformation, address _owner, address _DATABASE_CONTRACT, address _PRODUCT_FACTORY) public {
    name = _name;
    isConsumed = false;
    //ownerProducts = _ownerProducts;
    additionalInformation = _additionalInformation;

    DATABASE_CONTRACT = _DATABASE_CONTRACT;
    PRODUCT_FACTORY = _PRODUCT_FACTORY;

    Action memory creation;
    creation.handler = msg.sender;
    creation.description = "Product creation";
    creation.owner = _owner;
    creation.timestamp = now;
    creation.blockNumber = block.number;

    actions.push(creation);

    Database database = Database(DATABASE_CONTRACT);
    database.storeProductReference(this);
  }

  function () public {
    // If anyone wants to send Ether to this contract, the transaction gets rejected
    throw;
  }

  /* @notice Function to add an Action to the product.
     @param _description The description of the Action.
     @param _newProductNames In case that this Action creates more products from
            this Product, the names of the new products should be provided here.
     @param _newProductsAdditionalInformation In case that this Action creates more products from
            this Product, the additional information of the new products should be provided here.
     @param _consumed True if the product becomes consumed after the action. */
//   function addAction(bytes32 description, bytes32[] newProductsNames, bytes32[] newProductsAdditionalInformation, bool _consumed) notConsumed {
//     if (newProductsNames.length != newProductsAdditionalInformation.length) throw;

//     Action memory action;
//     action.handler = msg.sender;
//     action.description = description;
//     action.timestamp = now;
//     action.blockNumber = block.number;

//     actions.push(action);

//     ProductFactory productFactory = ProductFactory(PRODUCT_FACTORY);

//     for (uint i = 0; i < newProductsNames.length; ++i) {
//       address[] memory ownerProducts = new address[](1);
//       ownerProducts[0] = this;
//       productFactory.createProduct(newProductsNames[i], newProductsAdditionalInformation[i], ownerProducts, DATABASE_CONTRACT);
//     }

//     isConsumed = _consumed;
//   }

  /* @notice Function to merge some products to build a new one.
     @param otherProducts addresses of the other products to be merged.
     @param newProductsName Name of the new product resulting of the merge.
     @param newProductAdditionalInformation Additional information of the new product resulting of the merge.*/
//   function merge(address[] otherProducts, bytes32 newProductName, bytes32 newProductAdditionalInformation) notConsumed {
//     ProductFactory productFactory = ProductFactory(PRODUCT_FACTORY);
//     address newProduct = productFactory.createProduct(newProductName, newProductAdditionalInformation, otherProducts, DATABASE_CONTRACT);

//     this.collaborateInMerge(newProduct);
//     for (uint i = 0; i < otherProducts.length; ++i) {
//       Product prod = Product(otherProducts[i]);
//       prod.collaborateInMerge(newProduct);
//     }
//   }

  /* @notice Function to collaborate in a merge with some products to build a new one.
     @param newProductsAddress Address of the new product resulting of the merge. */
  function collaborateInMerge(address newProductAddress) public notConsumed {
    childProducts.push(newProductAddress);

    Action memory action;
    action.handler = this;
    action.description = "Collaborate in merge";
    action.timestamp = now;
    action.blockNumber = block.number;

    actions.push(action);

    this.consume();
  }

  /* @notice Function to consume the Product */
  function consume() public notConsumed {
    isConsumed = true;
  }
}

/* @dev This contract represents a product factory which represents products to be tracked in
   the TODO put name of platform ** platform. This product lets the handlers to register actions
   on it or even combine it with other products. */
contract ProductFactory {

      /////////////////
     // Constructor //
    /////////////////

    /* @notice Constructor to create a Product Factory */
    function ProductFactory() public {}

    function () public {
      // If anyone wants to send Ether to this contract, the transaction gets rejected
      throw;
    }

    /* @notice Function to create a Product
       @param _name The name of the Product
       @param _additionalInformation Additional information about the Product,
              generally as a JSON object.
       @param _ownerProducts Addresses of the owner of the Product.
       @param _DATABASE_CONTRACT Reference to its database contract */
    function createProduct(string _name, string _additionalInformation, address _owner, address DATABASE_CONTRACT) public returns(address) {
      return new Product(_name, _additionalInformation, _owner, DATABASE_CONTRACT, this);
    }
}
