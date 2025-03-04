from typing import Optional

from pydantic import BaseModel


class ResponseModel(BaseModel):
    uid: str
    question_id: str
    year: int
    answer: Optional[str]


class ProgramModel(BaseModel):
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
