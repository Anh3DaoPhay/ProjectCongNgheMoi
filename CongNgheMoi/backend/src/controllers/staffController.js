const {
  listDishCategories,
  createDishCategory,
  updateDishCategory,
  deleteDishCategory,
  listMenu,
  createDish,
  updateDish,
  updateDishImage,
  deleteDish,
  getMyCanteen,
  updateMyCanteen,
  listPromotions,
  createPromotion,
  updatePromotion,
  deletePromotion,
  listOrderRequests,
  updateOrderStatus,
  getOrderStatsByDish,
} = require("../services/staffService");
const { saveCroppedDishImage } = require("../config/upload");

async function getMenu(req, res, next) {
  try {
    const rows = await listMenu(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function getCategories(req, res, next) {
  try {
    const rows = await listDishCategories(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function addCategory(req, res, next) {
  try {
    const category = await createDishCategory(req.auth, req.body);
    res.status(201).json(category);
  } catch (error) {
    next(error);
  }
}

async function editCategory(req, res, next) {
  try {
    const category = await updateDishCategory(req.auth, req.params.categoryId, req.body);
    res.json(category);
  } catch (error) {
    next(error);
  }
}

async function removeCategory(req, res, next) {
  try {
    const result = await deleteDishCategory(req.auth, req.params.categoryId);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function addDish(req, res, next) {
  try {
    const dish = await createDish(req.auth, req.body);
    res.status(201).json(dish);
  } catch (error) {
    next(error);
  }
}

async function editDish(req, res, next) {
  try {
    const dish = await updateDish(req.auth, req.params.dishId, req.body);
    res.json(dish);
  } catch (error) {
    next(error);
  }
}

async function removeDish(req, res, next) {
  try {
    const result = await deleteDish(req.auth, req.params.dishId);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function getCanteen(req, res, next) {
  try {
    const canteen = await getMyCanteen(req.auth);
    res.json(canteen);
  } catch (error) {
    next(error);
  }
}

async function updateCanteen(req, res, next) {
  try {
    const canteen = await updateMyCanteen(req.auth, req.body);
    res.json(canteen);
  } catch (error) {
    next(error);
  }
}

async function getPromotions(req, res, next) {
  try {
    const rows = await listPromotions(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function addPromotion(req, res, next) {
  try {
    const promotion = await createPromotion(req.auth, req.body);
    res.status(201).json(promotion);
  } catch (error) {
    next(error);
  }
}

async function editPromotion(req, res, next) {
  try {
    const promotion = await updatePromotion(req.auth, req.params.promotionId, req.body);
    res.json(promotion);
  } catch (error) {
    next(error);
  }
}

async function removePromotion(req, res, next) {
  try {
    const result = await deletePromotion(req.auth, req.params.promotionId);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function getOrders(req, res, next) {
  try {
    const rows = await listOrderRequests(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function editOrderStatus(req, res, next) {
  try {
    const order = await updateOrderStatus(req.auth, req.params.orderId, req.body);
    res.json(order);
  } catch (error) {
    next(error);
  }
}

async function getDishOrderStats(req, res, next) {
  try {
    const rows = await getOrderStatsByDish(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function uploadDishImage(req, res, next) {
  try {
    if (!req.file) {
      const error = new Error("Ban chua chon anh mon an.");
      error.statusCode = 400;
      throw error;
    }

    const uploaded = await saveCroppedDishImage(req.file.buffer);
    const dishId = Number(req.params.dishId);

    if (Number.isInteger(dishId) && dishId > 0) {
      const dish = await updateDishImage(req.auth, dishId, uploaded.publicPath);
      res.json({
        imageUrl: uploaded.publicPath,
        dish,
      });
      return;
    }

    res.json({ imageUrl: uploaded.publicPath });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getCategories,
  addCategory,
  editCategory,
  removeCategory,
  getMenu,
  addDish,
  editDish,
  removeDish,
  getCanteen,
  updateCanteen,
  getPromotions,
  addPromotion,
  editPromotion,
  removePromotion,
  getOrders,
  editOrderStatus,
  getDishOrderStats,
  uploadDishImage,
};
