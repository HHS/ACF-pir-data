"""Pydantic models for data validation"""

from typing import Optional, Type

from pydantic import BaseModel, create_model


# Adapted from GPT 4.0
def make_fields_optional(model: Type[BaseModel]) -> Type[BaseModel]:
    """Convert all fields in a model to optional"""
    # Create a dictionary to hold the new field definitions
    new_fields = {}

    # Iterate over the fields of the original model
    for field_name, field in model.__annotations__.items():
        # Set the field type to Optional and default value to None
        new_fields[field_name] = (Optional[field], None)

    # Create a new model with the modified fields
    optional_model = create_model(model.__name__ + "Optional", **new_fields)

    return optional_model


class ResponseModel(BaseModel):
    """Model for validating the response data"""

    uid: str
    question_id: str
    year: int
    answer: Optional[str]


class ProgramModel(BaseModel):
    """Model for validating the program data"""

    uid: str
    year: int
    grantee_name: Optional[str]
    grant_number: Optional[str]
    program_address_line_1: Optional[str]
    program_address_line_2: Optional[str]
    program_agency_description: Optional[str]
    program_agency_type: Optional[str]
    program_city: Optional[str]
    program_email: Optional[str]
    program_name: Optional[str]
    program_number: Optional[str]
    program_phone: Optional[str]
    program_type: Optional[str]
    program_state: Optional[str]
    program_zip1: Optional[str]
    program_zip2: Optional[str]
    region: Optional[int]


class QuestionModel(BaseModel):
    """Model for validating the question data"""

    question_id: str
    year: int
    uqid: Optional[str]
    category: Optional[str]
    question_name: Optional[str]
    question_number: Optional[str]
    question_order: Optional[float]
    question_text: Optional[str]
    question_type: Optional[str]
    section: Optional[str]
    subsection: Optional[str]


QuestionModelOptional = make_fields_optional(QuestionModel)
QuestionModelOptional.__doc__ = (
    "Model for validating question data with all fields marked as optional"
)
