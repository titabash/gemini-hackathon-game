from fastapi import APIRouter

from controller.base_controller import router as base_router
from controller.genui_controller import router as genui_router
from controller.gm_controller import router as gm_router

router = APIRouter()

router.include_router(base_router, tags=["base"])
router.include_router(genui_router, tags=["genui"])
router.include_router(gm_router)
